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
      klass = Feature.enabled?(:group_mention_access_check) ? GroupMentionCheckAllUsers : GroupMention # rubocop:disable Gitlab/FeatureFlagWithoutActor -- no actor needed

      Gitlab::Metrics.measure(:integrations_group_mention_execution) do
        klass.new(@mentionable, @hook_data, @is_confidential).execute
      end
    end

    class GroupMention
      def initialize(mentionable, hook_data, is_confidential)
        @mentionable = mentionable
        @hook_data = hook_data
        @is_confidential = is_confidential
      end

      def execute
        return ServiceResponse.success if @mentionable.nil? || hook_data.nil?

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

        groups.each do |group|
          next unless execute_integrations_for?(group)

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

      def execute_integrations_for?(_)
        true # no-op
      end

      def groups
        mentionable.referenced_groups(mentionable.author)
      end
    end

    class GroupMentionCheckAllUsers < GroupMention
      GROUP_MENTION_LIMIT = 3

      def execute
        return mentionable_without_to_ability_name_service_error unless mentionable.respond_to?(:to_ability_name)

        super
      end

      private

      def execute_integrations_for?(group)
        # Check if direct group members have read access to the context of the group mention
        users = UsersFinder.new(nil, group_member_source_ids: [group.id]).execute
        ability = :"read_#{mentionable.to_ability_name}".to_sym

        users.all? { |user| user.can?(ability, mentionable) }
      end

      def groups
        hooks_type = confidential? ? :group_confidential_mention_hooks : :group_mention_hooks
        super.with_integrations
          .merge(Integration.public_send(hooks_type)).first(GROUP_MENTION_LIMIT) # rubocop:disable GitlabSecurity/PublicSend -- not user input
      end

      def mentionable_without_to_ability_name_service_error
        message = "Mentionable without to_ability_name: #{mentionable.class}"
        Gitlab::IntegrationsLogger.error(message)
        ServiceResponse.error(message: message)
      end
    end
  end
end
