# frozen_string_literal: true

module Mutations
  module Ml
    module Models
      class Delete < Base
        graphql_name 'MlModelDelete'

        include FindsProject

        argument :id, ::Types::GlobalIDType[::Ml::Model],
          required: true,
          description: 'Global ID of the model to be deleted.'

        def resolve(**args)
          project = authorized_find!(args[:project_path])

          model = ::Ml::Model.by_project_id_and_id(project.id, args[:id].model_id)

          return { errors: ['Model not found'] } unless model

          result = ::Ml::DestroyModelService.new(model, current_user).execute

          {
            model: result.payload[:model],
            errors: result.errors
          }
        end
      end
    end
  end
end
