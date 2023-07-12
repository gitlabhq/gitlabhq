# frozen_string_literal: true

# GroupMentionService class
#
# Used for sending group mention notifications
#
# Ex.
#   Integrations::GroupMentionService.new(mentionable, hook_data: data, is_confidential: true).execute
#
module Integrations
  class GroupMentionService
    def initialize(mentionable, hook_data:, is_confidential:)
      @mentionable = mentionable
      @hook_data = hook_data
      @is_confidential = is_confidential
    end

    def execute
      return ServiceResponse.success if mentionable.nil? || hook_data.nil?

      @hook_data = hook_data.clone
      # Fake a "group_mention" object kind so integrations can handle this as a separate class of event
      hook_data[:object_attributes][:object_kind] = hook_data[:object_kind]
      hook_data[:object_kind] = 'group_mention'

      if confidential?
        hook_data[:event_type] = 'group_confidential_mention'
        hook_scope = :group_confidential_mention_hooks
      else
        hook_data[:event_type] = 'group_mention'
        hook_scope = :group_mention_hooks
      end

      groups = mentionable.referenced_groups(mentionable.author)
      groups.each do |group|
        group_hook_data = hook_data.merge(
          mentioned: {
            object_kind: 'group',
            name: group.full_path,
            url: group.web_url
          }
        )
        group.execute_integrations(group_hook_data, hook_scope)
      end

      ServiceResponse.success
    end

    private

    attr_reader :mentionable, :hook_data, :is_confidential

    def confidential?
      return is_confidential if is_confidential.present?

      mentionable.project.visibility_level != Gitlab::VisibilityLevel::PUBLIC
    end
  end
end
