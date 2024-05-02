# frozen_string_literal: true

module Resolvers
  module AlertManagement
    class AlertStatusCountsResolver < BaseResolver
      type Types::AlertManagement::AlertStatusCountsType, null: true

      argument :search, GraphQL::Types::String,
        description: 'Search query for title, description, service, or monitoring_tool.',
        required: false

      argument :assignee_username, GraphQL::Types::String,
        required: false,
        description: 'Username of a user assigned to the issue.'

      def resolve(**args)
        ::Gitlab::AlertManagement::AlertStatusCounts.new(context[:current_user], object, args)
      end
    end
  end
end
