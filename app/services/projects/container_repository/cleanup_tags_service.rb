# frozen_string_literal: true

module Projects
  module ContainerRepository
    class CleanupTagsService < BaseService
      include ::Gitlab::Utils::StrongMemoize

      def execute(container_repository)
        return error('access denied') unless can_destroy?
        return error('invalid regex') unless valid_regex?

        tags = container_repository.tags
        original_size = tags.size

        tags = without_latest(tags)
        tags = filter_by_name(tags)

        before_truncate_size = tags.size
        tags = truncate(tags)
        after_truncate_size = tags.size

        cached_tags_count = populate_tags_from_cache(container_repository, tags) || 0

        tags = filter_keep_n(container_repository, tags)
        tags = filter_by_older_than(container_repository, tags)

        delete_tags(container_repository, tags).tap do |result|
          result[:original_size] = original_size
          result[:before_truncate_size] = before_truncate_size
          result[:after_truncate_size] = after_truncate_size
          result[:cached_tags_count] = cached_tags_count
          result[:before_delete_size] = tags.size
          result[:deleted_size] = result[:deleted]&.size

          result[:status] = :error if before_truncate_size != after_truncate_size
        end
      end

      private

      def delete_tags(container_repository, tags)
        return success(deleted: []) unless tags.any?

        tag_names = tags.map(&:name)

        service = Projects::ContainerRepository::DeleteTagsService.new(
          container_repository.project,
          current_user,
          tags: tag_names,
          container_expiration_policy: params['container_expiration_policy']
        )

        service.execute(container_repository)
      end

      def without_latest(tags)
        tags.reject(&:latest?)
      end

      def order_by_date(tags)
        now = DateTime.current
        tags.sort_by { |tag| tag.created_at || now }.reverse
      end

      def filter_by_name(tags)
        regex_delete = ::Gitlab::UntrustedRegexp.new("\\A#{params['name_regex_delete'] || params['name_regex']}\\z")
        regex_retain = ::Gitlab::UntrustedRegexp.new("\\A#{params['name_regex_keep']}\\z")

        tags.select do |tag|
          # regex_retain will override any overlapping matches by regex_delete
          regex_delete.match?(tag.name) && !regex_retain.match?(tag.name)
        end
      end

      def filter_keep_n(container_repository, tags)
        return tags unless params['keep_n']

        tags = order_by_date(tags)
        cache_tags(container_repository, tags.first(keep_n))
        tags.drop(keep_n)
      end

      def filter_by_older_than(container_repository, tags)
        return tags unless older_than

        older_than_timestamp = older_than_in_seconds.ago

        tags, tags_to_keep = tags.partition do |tag|
          tag.created_at && tag.created_at < older_than_timestamp
        end

        cache_tags(container_repository, tags_to_keep)

        tags
      end

      def can_destroy?
        return true if params['container_expiration_policy']

        can?(current_user, :destroy_container_image, project)
      end

      def valid_regex?
        %w(name_regex_delete name_regex name_regex_keep).each do |param_name|
          regex = params[param_name]
          ::Gitlab::UntrustedRegexp.new(regex) unless regex.blank?
        end
        true
      rescue RegexpError => e
        ::Gitlab::ErrorTracking.log_exception(e, project_id: project.id)
        false
      end

      def truncate(tags)
        return tags unless throttling_enabled?
        return tags if max_list_size == 0

        # truncate the list to make sure that after the #filter_keep_n
        # execution, the resulting list will be max_list_size
        truncated_size = max_list_size + keep_n

        return tags if tags.size <= truncated_size

        tags.sample(truncated_size)
      end

      def populate_tags_from_cache(container_repository, tags)
        cache(container_repository).populate(tags) if caching_enabled?(container_repository)
      end

      def cache_tags(container_repository, tags)
        cache(container_repository).insert(tags, older_than_in_seconds) if caching_enabled?(container_repository)
      end

      def cache(container_repository)
        # TODO Implement https://gitlab.com/gitlab-org/gitlab/-/issues/340277 to avoid passing
        # the container repository parameter which is bad for a memoized function
        strong_memoize(:cache) do
          ::Projects::ContainerRepository::CacheTagsCreatedAtService.new(container_repository)
        end
      end

      def caching_enabled?(container_repository)
        params['container_expiration_policy'] &&
          older_than.present? &&
          Feature.enabled?(:container_registry_expiration_policies_caching, container_repository.project)
      end

      def throttling_enabled?
        Feature.enabled?(:container_registry_expiration_policies_throttling)
      end

      def max_list_size
        ::Gitlab::CurrentSettings.current_application_settings.container_registry_cleanup_tags_service_max_list_size.to_i
      end

      def keep_n
        params['keep_n'].to_i
      end

      def older_than_in_seconds
        strong_memoize(:older_than_in_seconds) do
          ChronicDuration.parse(older_than).seconds
        end
      end

      def older_than
        params['older_than']
      end
    end
  end
end
