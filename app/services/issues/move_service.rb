module Issues
  class MoveService < Issues::BaseService
    def execute(issue_old, project_new)
      @issue_old = issue_old
      @issue_new = issue_old.dup
      @project_new = project_new
      @project_old = @project

      open_new_issue
      rewrite_notes
      close_old_issue
      notify_participants

      @issue_new
    end

    private

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
