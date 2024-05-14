# frozen_string_literal: true

module Types
  class DeploymentsOrderByInputType < BaseInputObject
    graphql_name 'DeploymentsOrderByInput'
    description 'Values for ordering deployments by a specific field'

    argument :created_at,
      Types::SortDirectionEnum,
      required: false,
      description: 'Order by Created time.'

    argument :finished_at,
      Types::SortDirectionEnum,
      required: false,
      description: 'Order by Finished time.'

    def prepare
      raise GraphQL::ExecutionError, 'orderBy parameter must contain one key-value pair.' unless to_h.size == 1

      super
    end
  end
end
