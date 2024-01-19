# frozen_string_literal: true

module Resolvers
  module Ml
    class FindModelsResolver < Resolvers::BaseResolver
      extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1

      type ::Types::Ml::ModelType.connection_type, null: true

      argument :name, GraphQL::Types::String,
        required: false,
        description: 'Search for names that include the string.'

      argument :order_by, ::Types::Ml::ModelsOrderByEnum,
        required: false,
        description: 'Ordering column. Default is created_at.'

      argument :sort, ::Types::SortDirectionEnum,
        required: false,
        description: 'Ordering column. Default is desc.'

      def resolve(**args)
        return unless Ability.allowed?(current_user, :read_model_registry, object)

        find_params = {
          name: args[:name],
          order_by: args[:order_by].to_s,
          sort: args[:sort].to_s
        }

        ::Projects::Ml::ModelFinder.new(object, find_params).execute
      end
    end
  end
end
