module Issues
  class MoveService < Issues::BaseService
    def initialize(project, current_user, params, issue, new_project_id)
      super(project, current_user, params)

      @issue_old = issue
      @issue_new = nil
      @project_old = @project

      if new_project_id
        @project_new = Project.find(new_project_id)
      end

      if @project_new == @project_old
        raise StandardError, 'Cannot move issue to project it originates from!'
      end
    end

    def execute
      return unless move?

      # Using trasaction because of a high resources footprint
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
      end

      notify_participants

      @issue_new
    end

    def move?
      @project_new && can_move?
    end

    private

    def can_move?
      can?(@current_user, :admin_issue, @project_old) &&
        can?(@current_user, :admin_issue, @project_new)
    end

    def create_new_issue
      new_params = { id: nil, iid: nil, milestone: nil, label_ids: [],
                     project: @project_new, author: @issue_old.author,
                     description: rewrite_references(@issue_old) }

      create_service = CreateService.new(@project_new, @current_user,
                                         params.merge(new_params))

      @issue_new = create_service.execute(set_author: false)
    end

    def rewrite_notes
      @issue_old.notes.find_each do |note|
        new_note = note.dup
        new_params = { project: @project_new, noteable: @issue_new,
                       note: rewrite_references(new_note) }

        new_note.update(new_params)
      end
    end

    def close_old_issue
      close_service = CloseService.new(@project_new, @current_user)
      close_service.execute(@issue_old, notifications: false, system_note: false)
    end

    def add_moved_from_note
      SystemNoteService.noteable_moved(:from, @issue_new, @project_new,
                                       @issue_old, @current_user)
    end

    def add_moved_to_note
      SystemNoteService.noteable_moved(:to, @issue_old, @project_old,
                                       @issue_new, @current_user)
    end

    def rewrite_references(noteable)
      content = noteable_content(noteable).dup
      unfolder = Gitlab::Gfm::ReferenceUnfolder.new(content, @project_old)
      unfolder.unfold(@project_new)
    end

    def noteable_content(noteable)
      case noteable
      when Issue then noteable.description
      when Note then noteable.note
      else
        raise 'Unexpected noteable while moving an issue!'
      end
    end

    def notify_participants
      notification_service.issue_moved(@issue_old, @issue_new, @current_user)
    end
  end
end
