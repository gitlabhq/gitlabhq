# frozen_string_literal: true

module Gitlab
  module MarkdownCache
    module Redis
      class Store
        EXPIRES_IN = 1.day

        def self.bulk_read(subjects)
          results = {}

          Gitlab::Redis::Cache.with do |r|
            r.pipelined do
              subjects.each do |subject|
                results[subject.cache_key] = new(subject).read
              end
            end
          end

          results
        end

        def initialize(subject)
          @subject = subject
          @loaded = false
        end

        def save(updates)
          @loaded = false

          Gitlab::Redis::Cache.with do |r|
            r.mapped_hmset(markdown_cache_key, updates)
            r.expire(markdown_cache_key, EXPIRES_IN)
          end
        end

        def read
          @loaded = true

          Gitlab::Redis::Cache.with do |r|
            r.mapped_hmget(markdown_cache_key, *fields)
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
      end
    end
  end
end
