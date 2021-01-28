# frozen_string_literal: true

class MergeRequestUserEntity < ::API::Entities::UserBasic
  include UserStatusTooltip

  expose :can_merge do |reviewer, options|
    options[:merge_request]&.can_be_merged_by?(reviewer)
  end
end

MergeRequestUserEntity.prepend_if_ee('EE::MergeRequestUserEntity')
