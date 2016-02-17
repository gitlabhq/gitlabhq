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

      open_new_issue
      rewrite_notes
      close_old_issue
      notify_participants

      @issue_new
    end

    def move?
      return false unless @project_new
      return false unless @issue_new
      return false unless can_move?

      true
    end

    private

    def can_move?
      true
    end

    def open_new_issue
      @issue_new.project = @project_new
      @issue_new.save!

      add_note_moved_from
    end

    def rewrite_notes
    end

    def close_old_issue
      add_note_moved_to
    end

    def notify_participants
    end

    def add_note_moved_from
      SystemNoteService.noteable_moved(:from, @issue_new, @project_new, @issue_old, @current_user)
    end

    def add_note_moved_to
      SystemNoteService.noteable_moved(:to, @issue_old, @project_old, @issue_new, @current_user)
    end
  end
end
