# frozen_string_literal: true

module Mutations
  module Ml
    module ModelVersions
      class Delete < BaseMutation
        graphql_name 'MlModelVersionDelete'

        authorize :write_model_registry

        argument :id, ::Types::GlobalIDType[::Ml::ModelVersion],
          required: true,
          description: 'Global ID of the model version to be deleted.'

        field :model_version, ::Types::Ml::ModelVersionType,
          description: 'Deleted model version.', null: true

        def resolve(**args)
          model_version = ::Ml::ModelVersion.find_by_id(args[:id].model_id)

          return { errors: [_('Model version not found')] } unless model_version

          authorize!(model_version.project)

          result = ::Ml::DestroyModelVersionService.new(model_version, current_user).execute

          {
            model_version: result.payload[:model_version],
            errors: result.errors
          }
        end
      end
    end
  end
end
