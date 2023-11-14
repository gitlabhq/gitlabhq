# frozen_string_literal: true

module Types
  module DataTransfer
    class ProjectDataTransferType < BaseType
      graphql_name 'ProjectDataTransfer'
      authorize

      field :total_egress, GraphQL::Types::BigInt,
        description: 'Total egress for that project in that period of time.',
        null: true, # disallow null once data_transfer_monitoring feature flag is rolled-out! https://gitlab.com/gitlab-org/gitlab/-/issues/397693
        extras: [:parent]

      def total_egress(parent:)
        return unless Feature.enabled?(:data_transfer_monitoring, parent.group)

        object[:egress_nodes].sum('repository_egress + artifacts_egress + packages_egress + registry_egress')
      end
    end
  end
end
