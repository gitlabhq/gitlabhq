# frozen_string_literal: true

module Resolvers
  module Ml
    class ModelDetailResolver < Resolvers::BaseResolver
      extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1

      type ::Types::Ml::ModelType, null: true

      argument :id, ::Types::GlobalIDType[::Ml::Model],
        required: true,
        description: 'ID of the model.'

      def resolve(id:)
        Gitlab::Graphql::Lazy.with_value(find_object(id: id)) do |ml_model|
          ml_model if Ability.allowed?(current_user, :read_model_registry, ml_model&.project)
        end
      end

      private

      def find_object(id:)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
