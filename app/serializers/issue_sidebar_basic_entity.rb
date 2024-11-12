# frozen_string_literal: true

class IssueSidebarBasicEntity < IssuableSidebarBasicEntity
  expose :due_date
  expose :confidential
  expose :severity

  expose :current_user, merge: true do
    expose :can_update_escalation_status, if: ->(issue, _) { issue.supports_escalation? } do |issue|
      can?(current_user, :update_escalation_status, issue.project)
    end
  end

  expose :show_crm_contacts do |issuable|
    current_user&.can?(:read_crm_contacts, issuable) &&
      CustomerRelations::Contact.exists_for_group?(issuable.project.crm_group)
  end
end

IssueSidebarBasicEntity.prepend_mod_with('IssueSidebarBasicEntity')
