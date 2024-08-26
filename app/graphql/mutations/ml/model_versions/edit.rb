# frozen_string_literal: true

module Mutations
  module Ml
    module ModelVersions
      class Edit < BaseMutation
        graphql_name 'MlModelVersionEdit'
        include FindsProject

        authorize :write_model_registry

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: "Project the model to mutate is in."

        argument :model_id, ::Types::GlobalIDType[::Ml::Model],
          required: true,
          description: 'Global ID of the model the version belongs to.'

        argument :version, GraphQL::Types::String,
          required: true,
          description: 'Model version.'

        argument :description, GraphQL::Types::String,
          required: true,
          description: 'Description of the model version.'

        field :model_version,
          Types::Ml::ModelVersionType,
          null: true,
          description: 'Model after mutation.'

        def resolve(**args)
          project = authorized_find!(args[:project_path])
          model = ::Ml::Model.by_project_id_and_id(project.id, args[:model_id].model_id)

          return { errors: ['Model not found'] } unless model

          service_response = ::Ml::ModelVersions::UpdateModelVersionService.new(project, model.name, args[:version],
            args[:description]).execute

          if service_response.success?
            {
              model_version: service_response.payload,
              errors: []
            }
          else
            {
              model_version: nil,
              errors: service_response.errors
            }
          end
        end
      end
    end
  end
end
