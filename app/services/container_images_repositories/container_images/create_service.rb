module ContainerImagesRepositories
  module ContainerImages
    class CreateService < BaseService
      def execute
        @container_image = container_images_repository.container_images.create(params)
        @container_image if @container_image.valid?
      end

      private

      def container_images_repository
        @container_images_repository ||= project.container_images_repository
      end
    end
  end
end
