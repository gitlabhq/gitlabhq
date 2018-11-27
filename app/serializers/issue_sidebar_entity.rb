# frozen_string_literal: true

class IssueSidebarEntity < IssuableSidebarEntity
  with_options if: { include_extras: true } do
    expose :assignees, using: API::Entities::UserBasic
  end
end
