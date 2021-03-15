# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Cache
        include ::Gitlab::Utils::StrongMemoize

        def initialize(cache, pipeline)
          if multiple_cache_per_job?
            cache = Array.wrap(cache)
            @cache = cache.map do |cache|
              Gitlab::Ci::Pipeline::Seed::Build::Cache
              .new(pipeline, cache)
            end
          else
            @cache = Gitlab::Ci::Pipeline::Seed::Build::Cache
              .new(pipeline, cache)
          end
        end

        def cache_attributes
          strong_memoize(:cache_attributes) do
            if multiple_cache_per_job?
              if @cache.empty?
                {}
              else
                { options: { cache: @cache.map(&:attributes) } }
              end
            else
              @cache.build_attributes
            end
          end
        end

        private

        def multiple_cache_per_job?
          strong_memoize(:multiple_cache_per_job) do
            ::Gitlab::Ci::Features.multiple_cache_per_job?
          end
        end
      end
    end
  end
end
