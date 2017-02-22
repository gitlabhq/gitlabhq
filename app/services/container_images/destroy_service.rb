module ContainerImages
  class DestroyService < BaseService
    def execute(container_image)
      return false unless can?(current_user, :update_container_image, project)

      container_image.destroy!
    end
  end
end
