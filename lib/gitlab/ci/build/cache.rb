# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Cache
        include ::Gitlab::Utils::StrongMemoize

        def initialize(cache, pipeline)
          cache = Array.wrap(cache)
          @cache = cache.map.with_index do |cache, index|
            prefix = cache_prefix(cache, index)

            Gitlab::Ci::Pipeline::Seed::Build::Cache
            .new(pipeline, cache, prefix)
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

        private

        # The below method fixes a bug related to incorrect caches being used
        # For more details please see: https://gitlab.com/gitlab-org/gitlab/-/issues/388374
        def cache_prefix(cache, index)
          files = cache.dig(:key, :files) if cache.is_a?(Hash) && cache[:key].is_a?(Hash)

          return index if files.blank?

          filenames = files.map { |file| file.split('.').first }.join('_')

          "#{index}_#{filenames}"
        end
      end
    end
  end
end
