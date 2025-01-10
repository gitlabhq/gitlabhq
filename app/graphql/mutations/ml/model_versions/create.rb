# frozen_string_literal: true

module Mutations
  module Ml
    module ModelVersions
      class Create < BaseMutation
        graphql_name 'MlModelVersionCreate'
        authorize :write_model_registry

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: "Project the model to mutate is in."

        include FindsProject

        argument :model_id, ::Types::GlobalIDType[::Ml::Model],
          required: true,
          description: 'Global ID of the model the version belongs to.'

        argument :version, GraphQL::Types::String,
          required: false,
          description: 'Model version.'

        argument :description, GraphQL::Types::String,
          required: false,
          description: 'Description of the model version.'

        argument :candidate_id, ::Types::GlobalIDType[::Ml::Candidate],
          required: false,
          description: 'Global ID of a candidate to promote optionally.'

        field :model_version,
          Types::Ml::ModelVersionType,
          null: true,
          description: 'Model after mutation.'

        def resolve(**args)
          project = authorized_find!(args[:project_path])
          model = ::Ml::Model.by_project_id_and_id(project.id, args[:model_id].model_id)

          return { errors: ['Model not found'] } unless model

          result = ::Ml::CreateModelVersionService.new(model,
            {
              version: args[:version],
              description: args[:description],
              candidate_id: args[:candidate_id],
              user: current_user
            }
          ).execute

          {
            model_version: result.payload[:model_version],
            errors: result.message
          }
        end
      end
    end
  end
end
