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
            Types::ContainerRepositoryType,
            null: false,
            description: 'The container repository policy after scheduling the deletion.'

      def resolve(id:)
        container_repository = authorized_find!(id: id)

        container_repository.delete_scheduled!
        DeleteContainerRepositoryWorker.perform_async(current_user.id, container_repository.id)
        track_event(:delete_repository, :container)

        {
          container_repository: container_repository,
          errors: []
        }
      end
    end
  end
end
