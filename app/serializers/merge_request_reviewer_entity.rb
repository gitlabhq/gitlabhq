# frozen_string_literal: true

class MergeRequestReviewerEntity < ::API::Entities::UserBasic
  expose :can_merge do |reviewer, options|
    options[:merge_request]&.can_be_merged_by?(reviewer)
  end
end

MergeRequestReviewerEntity.prepend_if_ee('EE::MergeRequestReviewerEntity')
