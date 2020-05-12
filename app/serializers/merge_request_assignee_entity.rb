# frozen_string_literal: true

class MergeRequestAssigneeEntity < ::API::Entities::UserBasic
  expose :can_merge do |assignee, options|
    options[:merge_request]&.can_be_merged_by?(assignee)
  end
end

MergeRequestAssigneeEntity.prepend_if_ee('EE::MergeRequestAssigneeEntity')
