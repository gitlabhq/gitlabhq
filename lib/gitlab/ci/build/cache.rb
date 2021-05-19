# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Cache
        include ::Gitlab::Utils::StrongMemoize

        def initialize(cache, pipeline)
          cache = Array.wrap(cache)
          @cache = cache.map do |cache|
            Gitlab::Ci::Pipeline::Seed::Build::Cache
            .new(pipeline, cache)
          end
        end

        def cache_attributes
          strong_memoize(:cache_attributes) do
            if @cache.empty?
              {}
            else
              { options: { cache: @cache.map(&:attributes) } }
            end
          end
        end
      end
    end
  end
end
