# frozen_string_literal: true

module Mutations
  module Ml
    module Models
      class Edit < Base
        graphql_name 'MlModelEdit'

        include FindsProject

        argument :model_id, GraphQL::Types::Int,
          required: false,
          description: 'Id of the model.'

        argument :name, GraphQL::Types::String,
          required: true,
          description: 'Name of the model.'

        argument :description, GraphQL::Types::String,
          required: false,
          description: 'Description of the model.'

        def resolve(project_path:, name:, model_id:, description:)
          project = authorized_find!(project_path)
          model = ::Ml::FindModelService.new(project, name, model_id).execute
          service_response = ::Ml::UpdateModelService.new(model, description).execute

          if service_response.success?
            {
              model: service_response.payload,
              errors: []
            }
          else
            {
              model: nil,
              errors: service_response.errors
            }
          end
        end
      end
    end
  end
end
