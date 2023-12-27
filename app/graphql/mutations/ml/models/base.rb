# frozen_string_literal: true

module Mutations
  module Ml
    module Models
      class Base < BaseMutation
        authorize :write_model_registry

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: "Project the model to mutate is in."

        field :model,
          Types::Ml::ModelType,
          null: true,
          description: 'Model after mutation.'
      end
    end
  end
end
