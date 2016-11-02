module ContainerImagesRepositories
  module ContainerImages
    class DestroyService < BaseService
      def execute(container_image)
        return false unless container_image

        container_image.destroy
      end
    end
  end
end
