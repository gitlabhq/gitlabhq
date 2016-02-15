module Issues
  class MoveService < Issues::BaseService
    def execute(issue_old, project_new)
      @issue_old = issue_old
      @issue_new = issue_old.dup
      @project_new = project_new

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
    end

    def add_note_moved_to
      SystemNoteService.issue_moved_to_another_project(@issue_old, @project, @project_new, @current_user)
    end
  end
end
