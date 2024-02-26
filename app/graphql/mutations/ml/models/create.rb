# frozen_string_literal: true

module Mutations
  module Ml
    module Models
      class Create < Base
        graphql_name 'MlModelCreate'

        include FindsProject

        argument :name, GraphQL::Types::String,
          required: true,
          description: 'Name of the model.'

        argument :description, GraphQL::Types::String,
          required: false,
          description: 'Description of the model.'

        def resolve(**args)
          project = authorized_find!(args[:project_path])

          service_response = ::Ml::CreateModelService.new(project, args[:name], current_user,
            args[:description]).execute

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
