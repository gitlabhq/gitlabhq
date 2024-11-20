# frozen_string_literal: true

module Mutations
  module ContainerRepositories
    class Destroy < ::Mutations::ContainerRepositories::DestroyBase
      graphql_name 'DestroyContainerRepository'

      authorize :destroy_container_image

      argument :id,
        ::Types::GlobalIDType[::ContainerRepository],
        required: true,
        description: 'ID of the container repository.'

      field :container_repository,
        Types::ContainerRegistry::ContainerRepositoryType,
        null: false,
        description: 'Container repository policy after scheduling the deletion.'

      def resolve(id:)
        container_repository = authorized_find!(id: id)

        container_repository.delete_scheduled! && audit_event(container_repository)

        track_event(:delete_repository, :container)

        {
          container_repository: container_repository,
          errors: []
        }
      end

      private

      def audit_event(repository)
        # defined in EE
      end
    end
  end
end

Mutations::ContainerRepositories::Destroy.prepend_mod
