# frozen_string_literal: true

module Projects
  module ContainerRepository
    class DestroyService < BaseService
      CLEANUP_TAGS_SERVICE_PARAMS = {
        'name_regex_delete' => '.*',
        'container_expiration_policy' => true # to avoid permissions checks
      }.freeze

      def execute(container_repository, disable_timeout: true)
        return false unless can?(current_user, :update_container_image, project)

        # Delete tags outside of the transaction to avoid hitting an idle-in-transaction timeout
        if Feature.enabled?(:use_delete_tags_service_on_destroy_service)
          unless delete_tags(container_repository, disable_timeout) &&
              destroy_container_repository(container_repository)
            container_repository.delete_failed!
          end
        else
          container_repository.delete_tags!
          container_repository.delete_failed! unless container_repository.destroy
        end
      end

      private

      def delete_tags(container_repository, disable_timeout)
        service = Projects::ContainerRepository::CleanupTagsService.new(
          container_repository: container_repository,
          params: CLEANUP_TAGS_SERVICE_PARAMS.merge('disable_timeout' => disable_timeout)
        )
        result = service.execute
        return true if result[:status] == :success

        log_error(error_message(container_repository, 'error in deleting tags'))
        false
      end

      def destroy_container_repository(container_repository)
        return true if container_repository.destroy

        log_error(error_message(container_repository, container_repository.errors.full_messages.join('. ')))
        false
      end

      def error_message(container_repository, message)
        "Container repository with ID: #{container_repository.id} and path: #{container_repository.path}" \
        " failed with message: #{message}"
      end
    end
  end
end
