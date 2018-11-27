# frozen_string_literal: true

class MergeRequestSidebarEntity < IssuableSidebarEntity
  with_options if: { include_basic: true } do
    expose :assignee, using: API::Entities::UserBasic

    expose :can_merge do |issuable|
      issuable.can_be_merged_by?(issuable.assignee) if issuable.assignee
    end
  end
end
