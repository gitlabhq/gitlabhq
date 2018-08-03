module EpicIssues
  class DestroyService < IssuableLinks::DestroyService
    def execute
      result = super
      link.epic.update_start_and_due_dates
      result
    end

    private

    def source
      @source ||= link.epic
    end

    def target
      @target ||= link.issue
    end

    def permission_to_remove_relation?
      can?(current_user, :admin_epic_issue, target) && can?(current_user, :admin_epic, source)
    end

    def create_notes
      SystemNoteService.epic_issue(source, target, current_user, :removed)
      SystemNoteService.issue_on_epic(target, source, current_user, :removed)
    end
  end
end
