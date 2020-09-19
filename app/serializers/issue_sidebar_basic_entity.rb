# frozen_string_literal: true

class IssueSidebarBasicEntity < IssuableSidebarBasicEntity
  expose :due_date
  expose :confidential
  expose :severity
end

IssueSidebarBasicEntity.prepend_if_ee('EE::IssueSidebarBasicEntity')
