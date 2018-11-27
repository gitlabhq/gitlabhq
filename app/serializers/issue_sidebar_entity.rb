# frozen_string_literal: true

class IssueSidebarEntity < IssuableSidebarEntity
  with_options if: { include_basic: true } do
    expose :due_date
    expose :confidential
  end

  with_options if: { include_extras: true } do
    expose :assignees, using: API::Entities::UserBasic
  end
end
