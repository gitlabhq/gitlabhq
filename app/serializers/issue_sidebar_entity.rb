class IssueSidebarEntity < IssuableSidebarEntity
  expose :assignees, using: API::Entities::UserBasic
end
