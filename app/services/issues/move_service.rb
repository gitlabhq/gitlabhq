module Issues
  class MoveService < Issues::BaseService
    class MoveError < StandardError; end

    def execute(issue, new_project)
      @old_issue = issue
      @old_project = @project
      @new_project = new_project

      unless issue.can_move?(current_user, new_project)
        raise MoveError, 'Cannot move issue due to insufficient permissions!'
      end

      if @project == new_project
        raise MoveError, 'Cannot move issue to project it originates from!'
      end

      # Using transaction because of a high resources footprint
      # on rewriting notes (unfolding references)
      #
      ActiveRecord::Base.transaction do
        # New issue tasks
        #
        @new_issue = create_new_issue

        rewrite_notes
        add_note_moved_from

        # Old issue tasks
        #
        add_note_moved_to
        close_issue
        mark_as_moved
      end

      notify_participants

      @new_issue
    end

    private

    def create_new_issue
      new_params = { id: nil, iid: nil, label_ids: [], milestone: nil,
                     project: @new_project, author: @old_issue.author,
                     description: unfold_references(@old_issue.description) }

      new_params = @old_issue.serializable_hash.merge(new_params)
      CreateService.new(@new_project, @current_user, new_params).execute
    end

    def rewrite_notes
      @old_issue.notes.find_each do |note|
        new_note = note.dup
        new_params = { project: @new_project, noteable: @new_issue,
                       note: unfold_references(new_note.note),
                       created_at: note.created_at }

        new_note.update(new_params)
      end
    end

    def close_issue
      close_service = CloseService.new(@old_project, @current_user)
      close_service.execute(@old_issue, notifications: false, system_note: false)
    end

    def add_note_moved_from
      SystemNoteService.noteable_moved(@new_issue, @new_project,
                                       @old_issue, @current_user,
                                       direction: :from)
    end

    def add_note_moved_to
      SystemNoteService.noteable_moved(@old_issue, @old_project,
                                       @new_issue, @current_user,
                                       direction: :to)
    end

    def unfold_references(content)
      rewriter = Gitlab::Gfm::ReferenceRewriter.new(content, @old_project,
                                                    @current_user)
      rewriter.rewrite(@new_project)
    end

    def notify_participants
      notification_service.issue_moved(@old_issue, @new_issue, @current_user)
    end

    def mark_as_moved
      @old_issue.update(moved_to: @new_issue)
    end
  end
end
