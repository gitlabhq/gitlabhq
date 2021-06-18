# frozen_string_literal: true

module Gitlab
  module Integrations
    class StiType < ActiveRecord::Type::String
      NAMESPACED_INTEGRATIONS = Set.new(%w(
        Asana Assembla Bamboo Bugzilla Buildkite Campfire Confluence CustomIssueTracker Datadog
        Discord DroneCi EmailsOnPush Ewm ExternalWiki Flowdock HangoutsChat Irker Jenkins Jira Mattermost
        MattermostSlashCommands MicrosoftTeams MockCi MockMonitoring Packagist PipelinesEmail Pivotaltracker
        Prometheus Pushover Redmine Slack SlackSlashCommands Teamcity UnifyCircuit Youtrack WebexTeams
      )).freeze

      def cast(value)
        new_cast(value) || super
      end

      def serialize(value)
        new_serialize(value) || super
      end

      def deserialize(value)
        value
      end

      def changed?(original_value, value, _new_value_before_type_cast)
        original_value != serialize(value)
      end

      def changed_in_place?(original_value_for_database, value)
        original_value_for_database != serialize(value)
      end

      private

      def namespaced_integrations
        NAMESPACED_INTEGRATIONS
      end

      def new_cast(value)
        value = prepare_value(value)
        return unless value

        stripped_name = value.delete_suffix('Service')
        return unless namespaced_integrations.include?(stripped_name)

        "Integrations::#{stripped_name}"
      end

      def new_serialize(value)
        value = prepare_value(value)
        return unless value&.starts_with?('Integrations::')

        "#{value.delete_prefix('Integrations::')}Service"
      end

      # Returns value cast to a `String`, or `nil` if value is `nil`.
      def prepare_value(value)
        return value if value.nil? || value.is_a?(String)

        value.to_s
      end
    end
  end
end

Gitlab::Integrations::StiType.prepend_mod
