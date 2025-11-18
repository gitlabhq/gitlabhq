# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Build
          class Cache
            def initialize(pipeline, cache, custom_key_prefix)
              @pipeline = pipeline
              local_cache = cache.to_h.deep_dup
              @key = local_cache.delete(:key)
              @paths = local_cache.delete(:paths)
              @policy = local_cache.delete(:policy)
              @untracked = local_cache.delete(:untracked)
              @when = local_cache.delete(:when)
              @unprotect = local_cache.delete(:unprotect)
              @custom_key_prefix = custom_key_prefix
              @fallback_keys = local_cache.delete(:fallback_keys)

              raise ArgumentError, "unknown cache keys: #{local_cache.keys}" if local_cache.any?
            end

            def attributes
              {
                key: key_string,
                paths: @paths,
                policy: @policy,
                untracked: @untracked,
                when: @when,
                unprotect: @unprotect,
                fallback_keys: @fallback_keys
              }.compact
            end

            def build_attributes
              { options: { cache: attributes.presence }.compact }
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

              @key[:prefix] ||= @custom_key_prefix.to_s
              [@key[:prefix], cache_key_digest].select(&:present?).join('-')
            end

            def cache_key_digest
              return hash_of_file_contents || 'default' if @key[:files]
              return hash_of_the_latest_changes || 'default' if @key[:files_commits]

              'default'
            end

            def hash_of_file_contents
              expanded_paths = expand_file_patterns(files)
              return unless expanded_paths.any?

              blob_references = expanded_paths.map { |path| [@pipeline.sha, path] }
              content_hashes = @pipeline.project.repository
                .blobs_at(blob_references, blob_size_limit: 0)
                .map(&:id)

              digest_from_hashes(content_hashes)
            end

            def hash_of_the_latest_changes
              commit_ids = files_commits_files.map { |path| last_commit_id_for_path(path) }
              digest_from_hashes(commit_ids)
            end

            def digest_from_hashes(hashes)
              hashes = hashes.compact.sort.uniq
              Digest::SHA1.hexdigest(hashes.join('-')) if hashes.any?
            end

            def files
              @key[:files].to_a.select(&:present?).uniq
            end

            def files_commits_files
              @key[:files_commits].to_a.select(&:present?).uniq
            end

            def expand_file_patterns(patterns)
              @expanded_patterns ||= {}
              @expanded_patterns[patterns] ||= patterns.flat_map do |pattern|
                if pattern.include?('*')
                  @pipeline.project.repository.search_files_by_wildcard_path(pattern, @pipeline.sha)
                else
                  pattern
                end
              end.compact.uniq
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
