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

        if protected_for_delete?(container_repository)
          return {
            container_repository: container_repository,
            errors: ['Deleting the protected repository path is forbidden']
          }
        end

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

      def protected_for_delete?(container_repository)
        return false unless Feature.enabled?(:container_registry_protected_containers_delete,
          container_repository.project&.root_ancestor)

        service_response = ::ContainerRegistry::Protection::CheckRuleExistenceService.for_delete(
          current_user: current_user,
          project: container_repository.project,
          params: { repository_path: container_repository.path.to_s }
        ).execute

        service_response.success? && service_response[:protection_rule_exists?]
      end
    end
  end
end

Mutations::ContainerRepositories::Destroy.prepend_mod
