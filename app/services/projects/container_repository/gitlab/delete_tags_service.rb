# frozen_string_literal: true

module Projects
  module ContainerRepository
    module Gitlab
      class DeleteTagsService
        include BaseServiceUtility
        include ::Gitlab::Utils::StrongMemoize

        DISABLED_TIMEOUTS = [nil, 0].freeze

        TimeoutError = Class.new(StandardError)

        def initialize(container_repository, tag_names)
          @container_repository = container_repository
          @tag_names = tag_names
          @deleted_tags = []
        end

        # Delete tags by name with a single DELETE request. This is only supported
        # by the GitLab Container Registry fork. See
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/23325 for details.
        def execute
          return success(deleted: []) if @tag_names.empty?

          delete_tags
        rescue TimeoutError, ::Faraday::Error => e
          ::Gitlab::ErrorTracking.track_exception(e, tags_count: @tag_names&.size, container_repository_id: @container_repository&.id)
          error('error while deleting tags', nil, pass_back: { deleted: @deleted_tags, exception_class_name: e.class.name })
        end

        private

        def delete_tags
          start_time = Time.zone.now

          @tag_names.each do |name|
            raise TimeoutError if timeout?(start_time)

            if @container_repository.delete_tag_by_name(name)
              @deleted_tags.append(name)
            end
          end

          @deleted_tags.any? ? success(deleted: @deleted_tags) : error('could not delete tags')
        end

        def timeout?(start_time)
          return false unless throttling_enabled?
          return false if service_timeout.in?(DISABLED_TIMEOUTS)

          (Time.zone.now - start_time) > service_timeout
        end

        def throttling_enabled?
          strong_memoize(:feature_flag) do
            Feature.enabled?(:container_registry_expiration_policies_throttling)
          end
        end

        def service_timeout
          ::Gitlab::CurrentSettings.current_application_settings.container_registry_delete_tags_service_timeout
        end
      end
    end
  end
end
