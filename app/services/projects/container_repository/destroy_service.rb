# frozen_string_literal: true

module Projects
  module ContainerRepository
    class DestroyService < BaseService
      def execute(container_repository)
        return false unless can?(current_user, :update_container_image, project)

        # Delete tags outside of the transaction to avoid hitting an idle-in-transaction timeout
        container_repository.delete_tags!
        container_repository.delete_failed! unless container_repository.destroy
      end
    end
  end
end
