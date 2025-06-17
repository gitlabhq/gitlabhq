# frozen_string_literal: true

module Projects
  module ContainerRepository
    module Gitlab
      class DeleteTagsService
        include BaseServiceUtility
        include ::Gitlab::Utils::StrongMemoize
        include ::Projects::ContainerRepository::Gitlab::Timeoutable
        include ContainerRegistry::Protection::Concerns::TagRule

        PROTECTED_TAGS_ERROR_MESSAGE = 'cannot delete protected tag(s)'

        def initialize(current_user:, container_repository:, tag_names:)
          @current_user = current_user
          @container_repository = container_repository
          @project = container_repository.project
          @tag_names = tag_names
          @deleted_tags = []
        end

        # Delete tags by name with a single DELETE request. This is only supported
        # by the GitLab Container Registry fork. See
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/23325 for details.
        def execute
          return success(deleted: []) if tag_names.empty?

          filter_out_protected!
          return error(PROTECTED_TAGS_ERROR_MESSAGE, pass_back: { deleted: [] }) if tag_names.empty?

          delete_tags
        rescue TimeoutError, ::Faraday::Error => e
          ::Gitlab::ErrorTracking.track_exception(e, tags_count: tag_names&.size, container_repository_id: container_repository&.id)
          error('error while deleting tags', nil, pass_back: { deleted: deleted_tags, exception_class_name: e.class.name })
        end

        private

        attr_reader :project, :current_user, :container_repository, :deleted_tags, :tag_names

        def delete_tags
          start_time = Time.zone.now

          tag_names.each do |name|
            raise TimeoutError if timeout?(start_time)

            if container_repository.delete_tag(name)
              deleted_tags.append(name)
            end
          end

          deleted_tags.any? ? success(deleted: deleted_tags) : error("could not delete tags: #{tag_names.join(', ')}".truncate(1000))
        end

        def filter_out_protected!
          patterns = protected_patterns_for_delete(project:, current_user:)
          return if patterns.blank?

          tag_names.reject! do |tag_name|
            patterns.detect do |pattern|
              pattern.match?(tag_name)
            end
          end
        end
      end
    end
  end
end
