module Issues
  class MoveService < Issues::BaseService
    def initialize(project, current_user, params, issue, new_project_id)
      super(project, current_user, params)

      @issue_old = issue
      @issue_new = issue.dup
      @project_old = @project
      @project_new = Project.find(new_project_id) if new_project_id
    end

    def execute
      return unless move?

      ActiveRecord::Base.transaction do
        # New issue tasks
        #
        open_new_issue
        rewrite_notes
        add_moved_from_note

        # Old issue tasks
        #
        add_moved_to_note
        close_old_issue
      end

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
      @issue_new.iid = nil
      @issue_new.project = @project_new
      @issue_new.labels = []
      @issue_new.milestone = nil
      @issue_new.description = rewrite_references(@issue_old)
      @issue_new.save!
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
      @issue_old.update(state: :closed)
    end

    def notify_participants
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
      when Issue
        noteable.description
      when Note
        noteable.note
      else
        raise 'Unexpected noteable while moving an issue'
      end
    end
  end
end
