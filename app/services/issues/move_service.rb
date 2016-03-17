module Issues
  class MoveService < Issues::BaseService
    def initialize(project, current_user, params, issue, new_project_id)
      super(project, current_user, params)

      @issue_old = issue
      @issue_new = nil
      @project_old = @project

      if new_project_id.to_i > 0
        @project_new = Project.find(new_project_id)
      end

      if @project_new == @project_old
        raise StandardError, 'Cannot move issue to project it originates from!'
      end
    end

    def execute
      return unless move?

      # Using transaction because of a high resources footprint
      # on rewriting notes (unfolding references)
      #
      ActiveRecord::Base.transaction do
        # New issue tasks
        #
        create_new_issue
        rewrite_notes
        add_moved_from_note

        # Old issue tasks
        #
        add_moved_to_note
        close_old_issue
        mark_as_moved
      end

      notify_participants

      @issue_new
    end

    def move?
      @project_new && can_move?
    end

    private

    def can_move?
      @issue_old.can_move?(@current_user) &&
        @issue_old.can_move?(@current_user, @project_new)
    end

    def create_new_issue
      new_params = { id: nil, iid: nil, milestone: nil, label_ids: [],
                     project: @project_new, author: @issue_old.author,
                     description: unfold_references(@issue_old.description) }

      new_params = @issue_old.serializable_hash.merge(new_params)
      create_service = CreateService.new(@project_new, @current_user,
                                         new_params)

      @issue_new = create_service.execute(set_author: false)
    end

    def rewrite_notes
      @issue_old.notes.find_each do |note|
        new_note = note.dup
        new_params = { project: @project_new, noteable: @issue_new,
                       note: unfold_references(new_note.note) }

        new_note.update(new_params)
      end
    end

    def close_old_issue
      close_service = CloseService.new(@project_new, @current_user)
      close_service.execute(@issue_old, notifications: false, system_note: false)
    end

    def add_moved_from_note
      SystemNoteService.noteable_moved(@issue_new, @project_new,
                                       @issue_old, @current_user, direction: :from)
    end

    def add_moved_to_note
      SystemNoteService.noteable_moved(@issue_old, @project_old,
                                       @issue_new, @current_user, direction: :to)
    end

    def unfold_references(content)
      unfolder = Gitlab::Gfm::ReferenceUnfolder.new(content, @project_old)
      unfolder.unfold(@project_new)
    end

    def notify_participants
      notification_service.issue_moved(@issue_old, @issue_new, @current_user)
    end

    def mark_as_moved
      @issue_old.update(moved_to: @issue_new)
    end
  end
end
