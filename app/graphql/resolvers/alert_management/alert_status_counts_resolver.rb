# frozen_string_literal: true

module Resolvers
  module AlertManagement
    class AlertStatusCountsResolver < BaseResolver
      type Types::AlertManagement::AlertStatusCountsType, null: true

      argument :search, GraphQL::STRING_TYPE,
                description: 'Search criteria for filtering alerts. This will search on title, description, service, monitoring_tool.',
                required: false

      def resolve(**args)
        ::Gitlab::AlertManagement::AlertStatusCounts.new(context[:current_user], object, args)
      end
    end
  end
end
