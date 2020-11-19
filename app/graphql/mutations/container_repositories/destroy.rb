# frozen_string_literal: true

module Mutations
  module ContainerRepositories
    class Destroy < Mutations::BaseMutation
      include ::Mutations::PackageEventable

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

      private

      def find_object(id:)
        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ::Types::GlobalIDType[::ContainerRepository].coerce_isolated_input(id)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
