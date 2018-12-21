# frozen_string_literal: true

class MergeRequestSidebarBasicEntity < IssuableSidebarBasicEntity
  expose :assignee, if: lambda { |issuable| issuable.assignee } do
    expose :assignee, merge: true, using: API::Entities::UserBasic

    expose :can_merge do |issuable|
      issuable.can_be_merged_by?(issuable.assignee)
    end
  end
end
