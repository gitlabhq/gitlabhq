module ContainerImagesRepositories
  module ContainerImages
    class PushService < BaseService
      def execute(container_image_name, event)
        find_or_create_container_image(container_image_name).valid?
      end

      private

      def find_or_create_container_image(container_image_name)
        options = {name: container_image_name}
        container_images.find_by(options) ||
          ::ContainerImagesRepositories::ContainerImages::CreateService.new(project,
            current_user, options).execute
      end

      def container_images_repository
        @container_images_repository ||= project.container_images_repository
      end

      def container_images
        @container_images ||= container_images_repository.container_images
      end
    end
  end
end
