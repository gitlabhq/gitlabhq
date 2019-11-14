# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Build
          class Cache
            def initialize(pipeline, cache)
              @pipeline = pipeline
              local_cache = cache.to_h.deep_dup
              @key = local_cache.delete(:key)
              @paths = local_cache.delete(:paths)
              @policy = local_cache.delete(:policy)
              @untracked = local_cache.delete(:untracked)

              raise ArgumentError, "unknown cache keys: #{local_cache.keys}" if local_cache.any?
            end

            def build_attributes
              {
                options: {
                  cache: {
                    key: key_string,
                    paths: @paths,
                    policy: @policy,
                    untracked: @untracked
                  }.compact.presence
                }.compact
              }
            end

            private

            def key_string
              key_from_string || key_from_files
            end

            def key_from_string
              @key.to_s if @key.is_a?(String) || @key.is_a?(Symbol)
            end

            def key_from_files
              return unless @key.is_a?(Hash)

              [@key[:prefix], files_digest].select(&:present?).join('-')
            end

            def files_digest
              hash_of_the_latest_changes || 'default'
            end

            def hash_of_the_latest_changes
              return unless Feature.enabled?(:ci_file_based_cache, @pipeline.project, default_enabled: true)

              ids = files.map { |path| last_commit_id_for_path(path) }
              ids = ids.compact.sort.uniq

              Digest::SHA1.hexdigest(ids.join('-')) if ids.any?
            end

            def files
              @key[:files]
                .to_a
                .select(&:present?)
                .uniq
            end

            def last_commit_id_for_path(path)
              @pipeline.project.repository.last_commit_id_for_path(@pipeline.sha, path)
            end
          end
        end
      end
    end
  end
end
