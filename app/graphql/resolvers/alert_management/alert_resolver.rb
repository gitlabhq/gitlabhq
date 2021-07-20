# frozen_string_literal: true

module Resolvers
  module AlertManagement
    class AlertResolver < BaseResolver
      include LooksAhead

      argument :iid, GraphQL::STRING_TYPE,
                required: false,
                description: 'IID of the alert. For example, "1".'

      argument :statuses, [Types::AlertManagement::StatusEnum],
                as: :status,
                required: false,
                description: 'Alerts with the specified statues. For example, `[TRIGGERED]`.'

      argument :sort, Types::AlertManagement::AlertSortEnum,
                description: 'Sort alerts by this criteria.',
                required: false

      argument :domain, Types::AlertManagement::DomainFilterEnum,
                description: 'Filter query for given domain.',
                required: true,
                default_value: 'operations'

      argument :search, GraphQL::STRING_TYPE,
                description: 'Search query for title, description, service, or monitoring_tool.',
                required: false

      argument :assignee_username, GraphQL::STRING_TYPE,
                required: false,
                description: 'Username of a user assigned to the issue.'

      type Types::AlertManagement::AlertType, null: true

      def resolve_with_lookahead(**args)
        parent = object.respond_to?(:sync) ? object.sync : object
        return ::AlertManagement::Alert.none if parent.nil?

        apply_lookahead(::AlertManagement::AlertsFinder.new(context[:current_user], parent, args).execute)
      end

      def preloads
        {
          assignees: [:assignees],
          notes: [:ordered_notes, { ordered_notes: [:system_note_metadata, :project, :noteable] }],
          issue: [:issue]
        }
      end
    end
  end
end
