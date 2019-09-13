# frozen_string_literal: true

class IssueSidebarExtrasEntity < IssuableSidebarExtrasEntity
end

IssueSidebarExtrasEntity.prepend_if_ee('EE::IssueSidebarExtrasEntity')
