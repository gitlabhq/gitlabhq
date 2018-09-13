# frozen_string_literal: true

module Projects
  module ContainerRepository
    class DestroyService < BaseService
      def execute(container_repository)
        return false unless can?(current_user, :update_container_image, project)

        container_repository.destroy
      end
    end
  end
end
