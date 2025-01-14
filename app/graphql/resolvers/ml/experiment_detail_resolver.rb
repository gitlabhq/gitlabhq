# frozen_string_literal: true

module Resolvers
  module Ml
    class ExperimentDetailResolver < Resolvers::BaseResolver
      extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1

      type ::Types::Ml::ExperimentType, null: true

      argument :id, ::Types::GlobalIDType[::Ml::Experiment],
        required: true,
        description: 'ID of the experiment.'

      def resolve(id:)
        Gitlab::Graphql::Lazy.with_value(find_object(id: id)) do |experiment|
          experiment if Ability.allowed?(current_user, :read_model_experiments, experiment&.project)
        end
      end

      private

      def find_object(id:)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
