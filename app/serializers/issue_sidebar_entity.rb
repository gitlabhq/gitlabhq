# frozen_string_literal: true

class IssueSidebarEntity < IssuableSidebarEntity
  expose :assignees, using: API::Entities::UserBasic
end
