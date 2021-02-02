# frozen_string_literal: true

class MergeRequestUserEntity < ::API::Entities::UserBasic
  include UserStatusTooltip
  include RequestAwareEntity

  expose :can_merge do |reviewer, options|
    options[:merge_request]&.can_be_merged_by?(reviewer)
  end

  expose :can_update_merge_request do |reviewer, options|
    request.current_user&.can?(:update_merge_request, options[:merge_request])
  end

  expose :reviewed, if: -> (_, options) { options[:merge_request] && options[:merge_request].allows_reviewers? } do |reviewer, options|
    reviewer = options[:merge_request].find_reviewer(reviewer)

    reviewer&.reviewed?
  end
end

MergeRequestUserEntity.prepend_if_ee('EE::MergeRequestUserEntity')
