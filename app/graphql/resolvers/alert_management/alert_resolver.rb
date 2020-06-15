# frozen_string_literal: true

module Resolvers
  module AlertManagement
    class AlertResolver < BaseResolver
      include LooksAhead

      argument :iid, GraphQL::STRING_TYPE,
                required: false,
                description: 'IID of the alert. For example, "1"'

      argument :statuses, [Types::AlertManagement::StatusEnum],
                as: :status,
                required: false,
                description: 'Alerts with the specified statues. For example, [TRIGGERED]'

      argument :sort, Types::AlertManagement::AlertSortEnum,
                description: 'Sort alerts by this criteria',
                required: false

      argument :search, GraphQL::STRING_TYPE,
                description: 'Search criteria for filtering alerts. This will search on title, description, service, monitoring_tool.',
                required: false

      type Types::AlertManagement::AlertType, null: true

      def resolve_with_lookahead(**args)
        parent = object.respond_to?(:sync) ? object.sync : object
        return ::AlertManagement::Alert.none if parent.nil?

        apply_lookahead(::AlertManagement::AlertsFinder.new(context[:current_user], parent, args).execute)
      end

      def preloads
        {
          assignees: [:assignees],
          notes: [:ordered_notes, { ordered_notes: [:system_note_metadata, :project, :noteable] }]
        }
      end
    end
  end
end
