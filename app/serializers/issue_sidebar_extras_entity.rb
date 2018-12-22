# frozen_string_literal: true

class IssueSidebarExtrasEntity < IssuableSidebarExtrasEntity
  expose :assignees, using: API::Entities::UserBasic
end
