# frozen_string_literal: true

module Resolvers
  module Ml
    class FindModelVersionsResolver < Resolvers::BaseResolver
      extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1

      type ::Types::Ml::ModelType.connection_type, null: true

      argument :version, GraphQL::Types::String,
        required: false,
        description: 'Search for versions where the name includes the string.'

      argument :order_by, ::Types::Ml::ModelVersionsOrderByEnum,
        required: false,
        description: 'Ordering column. Default is created_at.'

      argument :sort, ::Types::SortDirectionEnum,
        required: false,
        description: 'Ordering column. Default is desc.'

      def resolve(**args)
        return unless Ability.allowed?(current_user, :read_model_registry, object.project)

        find_params = {
          version: args[:version],
          order_by: args[:order_by].to_s,
          sort: args[:sort].to_s
        }

        ::Projects::Ml::ModelVersionFinder.new(object, find_params).execute
      end
    end
  end
end
