module EpicIssues
  class DestroyService < IssuableLinks::DestroyService
    private

    def create_notes?
      false
    end

    def source
      @source ||= link.epic
    end

    def target
      @target ||= link.issue
    end

    def permission_to_remove_relation?
      can?(current_user, :admin_epic_issue, target) && can?(current_user, :admin_epic, source)
    end
  end
end
