# frozen_string_literal: true

class IssueSidebarBasicEntity < IssuableSidebarBasicEntity
  expose :due_date
  expose :confidential
end

IssueSidebarBasicEntity.prepend_if_ee('EE::IssueSidebarBasicEntity')
