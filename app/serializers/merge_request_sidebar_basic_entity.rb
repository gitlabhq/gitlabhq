# frozen_string_literal: true

class MergeRequestSidebarBasicEntity < IssuableSidebarBasicEntity
  expose :current_user, if: lambda { |_issuable| current_user } do
    expose :can_merge do |merge_request|
      merge_request.can_be_merged_by?(current_user)
    end
  end
end
