# frozen_string_literal: true

module Mutations
  module Ml
    module Models
      class Destroy < Base
        graphql_name 'MlModelDestroy'

        include FindsProject

        argument :id, ::Types::GlobalIDType[::Ml::Model],
          required: true,
          description: 'Global ID of the model to be deleted.'

        field :message, GraphQL::Types::String,
          null: true,
          description: 'Model deletion result message.'

        def resolve(**args)
          project = authorized_find!(args[:project_path])

          model = ::Ml::Model.by_project_id_and_id(project.id, args[:id].model_id)

          return { errors: ['Model not found'] } unless model

          result = ::Ml::DestroyModelService.new(model, current_user).execute

          {
            message: result.success? ? result[:message] : nil,
            errors: result.error? ? Array.wrap(result[:message]) : []
          }
        end
      end
    end
  end
end
