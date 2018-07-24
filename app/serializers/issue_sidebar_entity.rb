# frozen_string_literal: true

class IssueSidebarEntity < IssuableSidebarEntity
  prepend ::EE::IssueSidebarEntity

  expose :assignees, using: API::Entities::UserBasic
end
