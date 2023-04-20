# frozen_string_literal: true

module Types
  module DataTransfer
    class EgressNodeType < BaseObject
      authorize

      field :date, GraphQL::Types::String,
        description: 'First day of the node range. There is one node per month.',
        null: false

      field :total_egress, GraphQL::Types::BigInt,
        description: 'Total egress for that project in that period of time.',
        null: false

      field :repository_egress, GraphQL::Types::BigInt,
        description: 'Repository egress for that project in that period of time.',
        null: false

      field :artifacts_egress, GraphQL::Types::BigInt,
        description: 'Artifacts egress for that project in that period of time.',
        null: false

      field :packages_egress, GraphQL::Types::BigInt,
        description: 'Packages egress for that project in that period of time.',
        null: false

      field :registry_egress, GraphQL::Types::BigInt,
        description: 'Registry egress for that project in that period of time.',
        null: false
    end
  end
end
