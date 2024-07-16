# frozen_string_literal: true

class MergeRequestSidebarBasicEntity < IssuableSidebarBasicEntity
  expose :current_user, if: ->(_issuable) { current_user } do
    expose :can_merge do |merge_request|
      merge_request.can_be_merged_by?(current_user)
    end

    expose :can_update_merge_request do |merge_request|
      current_user.can?(:update_merge_request, merge_request)
    end
  end
end

MergeRequestSidebarBasicEntity.prepend_mod_with('MergeRequestSidebarBasicEntity')
