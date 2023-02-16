# frozen_string_literal: true

module Types
  module DataTransfer
    class ProjectDataTransferType < BaseType
      graphql_name 'ProjectDataTransfer'
      authorize

      field :total_egress, GraphQL::Types::BigInt,
        description: 'Total egress for that project in that period of time.',
        null: true # disallow null once data_transfer_monitoring feature flag is rolled-out!

      def total_egress(**_)
        return unless Feature.enabled?(:data_transfer_monitoring)

        40_000_000
      end
    end
  end
end
