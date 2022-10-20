# frozen_string_literal: true

module Projects
  module ContainerRepository
    module ThirdParty
      class CleanupTagsService < CleanupTagsBaseService
        def initialize(container_repository:, current_user: nil, params: {})
          super

          @params = params.dup
          @counts = { cached_tags_count: 0 }
        end

        def execute
          tags = container_repository.tags
          @counts[:original_size] = tags.size

          filter_out_latest!(tags)
          filter_by_name!(tags)

          tags = truncate(tags)
          populate_from_cache(tags)

          tags = filter_keep_n(tags)
          tags = filter_by_older_than(tags)

          @counts[:before_delete_size] = tags.size

          delete_tags(tags).merge(@counts).tap do |result|
            result[:deleted_size] = result[:deleted]&.size

            result[:status] = :error if @counts[:before_truncate_size] != @counts[:after_truncate_size]
          end
        end

        private

        def filter_keep_n(tags)
          tags, tags_to_keep = partition_by_keep_n(tags)

          cache_tags(tags_to_keep)

          tags
        end

        def filter_by_older_than(tags)
          tags, tags_to_keep = partition_by_older_than(tags)

          cache_tags(tags_to_keep)

          tags
        end

        def pushed_at(tag)
          tag.created_at
        end

        def truncate(tags)
          @counts[:before_truncate_size] = tags.size
          @counts[:after_truncate_size] = tags.size

          return tags if max_list_size == 0

          # truncate the list to make sure that after the #filter_keep_n
          # execution, the resulting list will be max_list_size
          truncated_size = max_list_size + keep_n_as_integer

          return tags if tags.size <= truncated_size

          tags = tags.sample(truncated_size)
          @counts[:after_truncate_size] = tags.size
          tags
        end

        def populate_from_cache(tags)
          @counts[:cached_tags_count] = cache.populate(tags) if caching_enabled?
        end

        def cache_tags(tags)
          cache.insert(tags, older_than_in_seconds) if caching_enabled?
        end

        def cache
          strong_memoize(:cache) do
            ::Gitlab::ContainerRepository::Tags::Cache.new(container_repository)
          end
        end

        def caching_enabled?
          result = current_application_settings.container_registry_expiration_policies_caching &&
            container_expiration_policy &&
            older_than.present?
          !!result
        end

        def max_list_size
          current_application_settings.container_registry_cleanup_tags_service_max_list_size.to_i
        end

        def current_application_settings
          ::Gitlab::CurrentSettings.current_application_settings
        end
      end
    end
  end
end
