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
    include Gitlab::Utils::StrongMemoize

    GROUP_MENTION_LIMIT = 3

    def initialize(mentionable, hook_data:, is_confidential:)
      @mentionable = mentionable
      @hook_data = hook_data
      @is_confidential = is_confidential
    end

    def execute
      Gitlab::Metrics.measure(:integrations_group_mention_execution) { process }
    end

    private

    attr_reader :mentionable, :hook_data, :is_confidential

    def process
      return ServiceResponse.success if mentionable.nil?
      return mentionable_without_to_ability_name_service_error unless mentionable.respond_to?(:to_ability_name)

      hook_scope = confidential? ? :group_confidential_mention_hooks : :group_mention_hooks

      groups.each do |group|
        next unless execute_integrations_for?(group)

        group_hook_data = Gitlab::Lazy.new do
          group_mention_hook_data.merge(
            mentioned: {
              object_kind: 'group',
              name: group.full_path,
              url: group.web_url
            }
          )
        end

        group.execute_integrations(group_hook_data, hook_scope)
      end

      ServiceResponse.success
    end

    def group_mention_hook_data
      mention_hook_data = hook_data.clone
      # Fake a "group_mention" object kind so integrations can handle this as a separate class of event
      mention_hook_data[:object_attributes][:object_kind] = hook_data[:object_kind]
      mention_hook_data[:object_kind] = 'group_mention'

      mention_hook_data[:event_type] = if confidential?
                                         'group_confidential_mention'
                                       else
                                         'group_mention'
                                       end

      mention_hook_data
    end
    strong_memoize_attr :group_mention_hook_data

    def confidential?
      return is_confidential if is_confidential.present?

      mentionable.project.visibility_level != Gitlab::VisibilityLevel::PUBLIC
    end

    def execute_integrations_for?(group)
      # Check if direct group members have read access to the context of the group mention
      users = UsersFinder.new(nil, group_member_source_ids: [group.id]).execute
      ability = :"read_#{mentionable.to_ability_name}".to_sym

      users.all? { |user| user.can?(ability, mentionable) }
    end

    def groups
      hooks_type = confidential? ? :group_confidential_mention_hooks : :group_mention_hooks
      mentionable.referenced_groups(mentionable.author).with_integrations
        .merge(Integration.public_send(hooks_type)).first(GROUP_MENTION_LIMIT) # rubocop:disable GitlabSecurity/PublicSend -- not user input
    end

    def mentionable_without_to_ability_name_service_error
      message = "Mentionable without to_ability_name: #{mentionable.class}"
      Gitlab::IntegrationsLogger.error(message)
      ServiceResponse.error(message: message)
    end
  end
end
