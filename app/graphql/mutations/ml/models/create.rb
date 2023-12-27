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

          model = ::Ml::CreateModelService.new(project, args[:name], current_user, args[:description]).execute

          {
            model: model.persisted? ? model : nil,
            errors: errors_on_object(model)
          }
        end
      end
    end
  end
end
