# frozen_string_literal: true

class MergeRequestUserEntity < ::API::Entities::UserBasic
  include UserStatusTooltip
  include RequestAwareEntity

  def self.satisfies(*methods)
    ->(_, options) { methods.all? { |m| options[:merge_request].try(m) } }
  end

  expose :can_merge do |reviewer, options|
    options[:merge_request]&.can_be_merged_by?(reviewer)
  end

  expose :can_update_merge_request do |reviewer, options|
    request.current_user&.can?(:update_merge_request, options[:merge_request])
  end

  expose :reviewed, if: satisfies(:present?, :allows_reviewers?) do |user, options|
    options[:merge_request].find_reviewer(user)&.reviewed?
  end

  expose :approved, if: satisfies(:present?) do |user, options|
    # This approach is preferred over MergeRequest#approved_by? since this
    # makes one query per merge request, whereas #approved_by? makes one per user
    options[:merge_request].approvals.any? { |app| app.user_id == user.id }
  end

  expose :suggested, if: satisfies(:present?) do |user, options|
    options[:suggested]
  end
end

MergeRequestUserEntity.prepend_mod_with('MergeRequestUserEntity')
