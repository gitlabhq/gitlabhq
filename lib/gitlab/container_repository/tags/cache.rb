# frozen_string_literal: true

module Gitlab
  module ContainerRepository
    module Tags
      class Cache
        def initialize(container_repository)
          @container_repository = container_repository
          @cached_tag_names = Set.new
        end

        def populate(tags)
          return if tags.empty?

          # This will load all tags in one Redis roundtrip
          # the maximum number of tags is configurable and is set to 200 by default.
          # https://gitlab.com/gitlab-org/gitlab/blob/master/doc/user/packages/container_registry/index.md#set-cleanup-limits-to-conserve-resources
          keys = tags.map(&method(:cache_key))
          cached_tags_count = 0

          with_redis do |redis|
            tags.zip(redis.mget(keys)).each do |tag, created_at|
              next unless created_at

              tag.created_at = DateTime.rfc3339(created_at)
              @cached_tag_names << tag.name
              cached_tags_count += 1
            end
          end

          cached_tags_count
        end

        def insert(tags, max_ttl_in_seconds)
          return unless max_ttl_in_seconds
          return if tags.empty?

          # tags with nil created_at are not cacheable
          # tags already cached don't need to be cached again
          cacheable_tags = tags.select do |tag|
            tag.created_at.present? && !tag.name.in?(@cached_tag_names)
          end

          return if cacheable_tags.empty?

          now = Time.zone.now

          with_redis do |redis|
            # we use a pipeline instead of a MSET because each tag has
            # a specific ttl
            redis.pipelined do |pipeline|
              cacheable_tags.each do |tag|
                created_at = tag.created_at
                # ttl is the max_ttl_in_seconds reduced by the number
                # of seconds that the tag has already existed
                ttl = max_ttl_in_seconds - (now - created_at).seconds
                ttl = ttl.to_i
                pipeline.set(cache_key(tag), created_at.rfc3339, ex: ttl) if ttl > 0
              end
            end
          end
        end

        private

        def cache_key(tag)
          "container_repository:{#{@container_repository.id}}:tag:#{tag.name}:created_at"
        end

        def with_redis(&block)
          ::Gitlab::Redis::Cache.with(&block) # rubocop:disable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
