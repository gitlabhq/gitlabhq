# frozen_string_literal: true

module Gitlab
  module MarkdownCache
    module Redis
      class Store
        EXPIRES_IN = 1.day

        def self.bulk_read(subjects)
          results = {}

          data = Gitlab::Redis::Cache.with do |r|
            Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
              r.pipelined do |pipeline|
                subjects.each do |subject|
                  new(subject).read(pipeline)
                end
              end
            end
          end

          # enumerate data
          data.each_with_index do |elem, idx|
            results[subjects[idx].cache_key] = elem
          end

          results
        end

        def initialize(subject)
          @subject = subject
          @loaded = false
        end

        def save(updates)
          @loaded = false

          with_redis do |r|
            r.mapped_hmset(markdown_cache_key, updates)
            r.expire(markdown_cache_key, EXPIRES_IN)
          end
        end

        def read(pipeline = nil)
          @loaded = true

          if pipeline
            pipeline.mapped_hmget(markdown_cache_key, *fields)
          else
            with_redis do |r|
              r.mapped_hmget(markdown_cache_key, *fields)
            end
          end
        end

        def loaded?
          @loaded
        end

        private

        def fields
          @fields ||= @subject.cached_markdown_fields.html_fields + [:cached_markdown_version]
        end

        def markdown_cache_key
          unless @subject.respond_to?(:cache_key)
            raise Gitlab::MarkdownCache::UnsupportedClassError,
              "This class has no cache_key to use for caching"
          end

          "markdown_cache:#{@subject.cache_key}"
        end

        def with_redis(&block)
          Gitlab::Redis::Cache.with(&block) # rubocop:disable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
