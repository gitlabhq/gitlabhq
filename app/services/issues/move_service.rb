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
      close_old_issue
      add_moved_to_note

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
      @issue_new.project = @project_new
      @issue_new.save!
    end

    def rewrite_notes
      @issue_old.notes.find_each do |note|
        note_new = note.dup
        note_new.project = @project_new
        note_new.noteable = @issue_new
        note_new.save!
      end
    end

    def close_old_issue
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
