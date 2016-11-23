module ContainerImages
  class DestroyService < BaseService

    class DestroyError < StandardError; end

    def execute(container_image)
      @container_image = container_image

      return false unless can?(current_user, :remove_project, project)

      ContainerImage.transaction do
        container_image.destroy!

        unless remove_container_image_tags
          raise_error('Failed to remove container image tags. Please try again or contact administrator')
        end
      end

      true
    end

    private

    def raise_error(message)
      raise DestroyError.new(message)
    end

    def remove_container_image_tags
      container_image.delete_tags
    end
  end
end
