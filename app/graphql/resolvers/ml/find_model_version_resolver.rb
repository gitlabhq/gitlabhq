# frozen_string_literal: true

module Resolvers
  module Ml
    class FindModelVersionResolver < Resolvers::BaseResolver
      extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1

      type ::Types::Ml::ModelType, null: true

      argument :model_version_id, ::Types::GlobalIDType[::Ml::ModelVersion],
        required: false,
        description: 'Id of the version to be fetched.'

      def resolve(model_version_id:)
        Gitlab::Graphql::Lazy.with_value(find_object(id: model_version_id)) do |model_version|
          model_version if Ability.allowed?(current_user, :read_model_registry, model_version&.project) &&
            model_version.model_id == object.id
        end
      end

      def find_object(id:)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
