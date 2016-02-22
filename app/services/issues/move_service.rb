module Issues
  class MoveService < Issues::BaseService
    def initialize(project, current_user, params, issue)
      super(project, current_user, params)

      @issue_old = issue
      @issue_new = @issue_old.dup
      @project_old = @project

      if params['move_to_project_id']
        @project_new = Project.find(params['move_to_project_id'])
      end
    end

    def execute
      return unless move?

      # New issue tasks
      #
      open_new_issue
      rewrite_notes
      add_moved_from_note

      # Old issue tasks
      #
      add_moved_to_note
      close_old_issue

      # Notifications
      #
      notify_participants

      @issue_new
    end

    def move?
      @project_new && can_move?
    end

    private

    def can_move?
      can?(@current_user, :move_issue, @project_old) &&
        can?(@current_user, :move_issue, @project_new)
    end

    def open_new_issue
      @issue_new.update(project: @project_new)
    end

    def rewrite_notes
      @issue_old.notes.find_each do |note|
        new_note = note.dup
        new_note.update(project: @project_new, noteable: @issue_new)
      end
    end

    def close_old_issue
      @issue_old.update(state: :closed)
    end

    def notify_participants
    end

    def add_moved_from_note
      SystemNoteService.noteable_moved(:from, @issue_new, @project_new, @issue_old, @current_user)
    end

    def add_moved_to_note
      SystemNoteService.noteable_moved(:to, @issue_old, @project_old, @issue_new, @current_user)
    end
  end
end
