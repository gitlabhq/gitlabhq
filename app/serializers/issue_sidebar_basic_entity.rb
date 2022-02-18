# frozen_string_literal: true

class IssueSidebarBasicEntity < IssuableSidebarBasicEntity
  expose :due_date
  expose :confidential
  expose :severity

  expose :current_user, merge: true do
    expose :can_update_escalation_status, if: -> (issue, _) { issue.supports_escalation? } do |issue|
      can?(current_user, :update_escalation_status, issue.project)
    end
  end
end

IssueSidebarBasicEntity.prepend_mod_with('IssueSidebarBasicEntity')
