# frozen_string_literal: true

module Resolvers
  module AlertManagement
    class AlertResolver < BaseResolver
      include LooksAhead

      argument :iid, GraphQL::Types::String,
        required: false,
        description: 'IID of the alert. For example, "1".'

      argument :statuses, [Types::AlertManagement::StatusEnum],
        as: :status,
        required: false,
        description: 'Alerts with the specified statues. For example, `[TRIGGERED]`.'

      argument :sort, Types::AlertManagement::AlertSortEnum,
        description: 'Sort alerts by the criteria.',
        required: false

      argument :domain, Types::AlertManagement::DomainFilterEnum,
        description: 'Filter query for given domain.',
        required: true,
        default_value: 'operations'

      argument :search, GraphQL::Types::String,
        description: 'Search query for title, description, service, or monitoring_tool.',
        required: false

      argument :assignee_username, GraphQL::Types::String,
        required: false,
        description: 'Username of a user assigned to the issue.'

      type Types::AlertManagement::AlertType, null: true

      def resolve_with_lookahead(**args)
        parent = object.respond_to?(:sync) ? object.sync : object
        return ::AlertManagement::Alert.none if parent.nil?

        raise GraphQL::ExecutionError, error_message if alert_is_disabled?

        apply_lookahead(::AlertManagement::AlertsFinder.new(context[:current_user], parent, args).execute)
      end

      def preloads
        {
          assignees: [:assignees],
          notes: [:ordered_notes, { ordered_notes: [:system_note_metadata, :project, :noteable] }],
          issue: [:issue]
        }
      end

      private

      def alert_is_disabled?
        Feature.enabled?(:hide_incident_management_features, project)
      end

      def project
        if object.is_a?(::Project)
          object
        else
          object.project
        end
      end

      # This error is raised when the alert feature is disabled via feature flag.
      # Not yet a deprecated field, as the FF is disabled by default (see issue#537182).
      # If the FF is enabled in the future, we may need to consider deprecating this field.
      def error_message
        "Field 'alertManagementAlerts' doesn't exist on type 'Project'."
      end
    end
  end
end
