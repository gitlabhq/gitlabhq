# frozen_string_literal: true

module Projects
  module ContainerRepository
    class CleanupTagsService < CleanupTagsBaseService
      def initialize(container_repository, user = nil, params = {})
        @container_repository = container_repository
        @current_user = user
        @params = params.dup

        @project = container_repository.project
        @tags = container_repository.tags
        tags_size = @tags.size
        @counts = {
          original_size: tags_size,
          cached_tags_count: 0
        }
      end

      def execute
        return error('access denied') unless can_destroy?
        return error('invalid regex') unless valid_regex?

        filter_out_latest
        filter_by_name

        truncate
        populate_from_cache

        filter_keep_n
        filter_by_older_than

        delete_tags.merge(@counts).tap do |result|
          result[:before_delete_size] = @tags.size
          result[:deleted_size] = result[:deleted]&.size

          result[:status] = :error if @counts[:before_truncate_size] != @counts[:after_truncate_size]
        end
      end

      private

      def filter_keep_n
        @tags, tags_to_keep = partition_by_keep_n

        cache_tags(tags_to_keep)
      end

      def filter_by_older_than
        @tags, tags_to_keep = partition_by_older_than

        cache_tags(tags_to_keep)
      end

      def pushed_at(tag)
        tag.created_at
      end

      def truncate
        @counts[:before_truncate_size] = @tags.size
        @counts[:after_truncate_size] = @tags.size

        return if max_list_size == 0

        # truncate the list to make sure that after the #filter_keep_n
        # execution, the resulting list will be max_list_size
        truncated_size = max_list_size + keep_n_as_integer

        return if @tags.size <= truncated_size

        @tags = @tags.sample(truncated_size)
        @counts[:after_truncate_size] = @tags.size
      end

      def populate_from_cache
        @counts[:cached_tags_count] = cache.populate(@tags) if caching_enabled?
      end

      def cache_tags(tags)
        cache.insert(tags, older_than_in_seconds) if caching_enabled?
      end

      def cache
        strong_memoize(:cache) do
          ::Gitlab::ContainerRepository::Tags::Cache.new(@container_repository)
        end
      end

      def caching_enabled?
        result = ::Gitlab::CurrentSettings.current_application_settings.container_registry_expiration_policies_caching &&
                 container_expiration_policy &&
                 older_than.present?
        !!result
      end

      def max_list_size
        ::Gitlab::CurrentSettings.current_application_settings.container_registry_cleanup_tags_service_max_list_size.to_i
      end
    end
  end
end
