# frozen_string_literal: true

module Projects
  module ContainerRepository
    class CleanupTagsService < BaseContainerRepositoryService
      def execute
        return error('access denied') unless can_destroy?
        return error('invalid regex') unless valid_regex?

        cleanup_tags_service_class.new(container_repository: container_repository, current_user: current_user, params: params)
                                  .execute
      end

      private

      def cleanup_tags_service_class
        log_data = {
          container_repository_id: container_repository.id,
          container_repository_path: container_repository.path,
          project_id: project.id
        }

        if use_gitlab_service?
          log_info(log_data.merge(gitlab_cleanup_tags_service: true))
          ::Projects::ContainerRepository::Gitlab::CleanupTagsService
        else
          log_info(log_data.merge(third_party_cleanup_tags_service: true))
          ::Projects::ContainerRepository::ThirdParty::CleanupTagsService
        end
      end

      def use_gitlab_service?
        container_repository.gitlab_api_client.supports_gitlab_api?
      end

      def can_destroy?
        return true if container_expiration_policy

        can?(current_user, :destroy_container_image, project)
      end

      def valid_regex?
        %w[name_regex_delete name_regex name_regex_keep].each do |param_name|
          regex = params[param_name]
          ::Gitlab::UntrustedRegexp.new(regex) unless regex.blank?
        end
        true
      rescue RegexpError => e
        ::Gitlab::ErrorTracking.log_exception(e, project_id: project.id)
        false
      end

      def container_expiration_policy
        params['container_expiration_policy']
      end
    end
  end
end
