# frozen_string_literal: true

module Gitlab
  module Ci
    module Catalog
      module Bundle
        # Walks only each file's top-level `include:`, and ignores `rules:` while
        # walking so rule-guarded files are collected too.
        class Collector
          class CollectError < StandardError
            attr_reader :errors

            def initialize(errors)
              @errors = errors

              super(errors.join('; '))
            end
          end

          def initialize(project:, sha:, entry_path:)
            @project = project
            @sha = sha
            @entry_path = Gitlab::Utils.remove_leading_slashes(entry_path)
            @files = {}
            @errors = []
            @seen = Set[@entry_path]
          end

          def collect
            includes_level = Set[entry_path]
            includes_level = collect_level(includes_level) while includes_level.any?

            raise CollectError, errors if errors.any?

            files
          end

          private

          attr_reader :project, :sha, :entry_path, :files, :errors, :seen

          # Fetches one level of the include tree in a single call and returns the next.
          def collect_level(paths)
            check_file_limit!(files.size + paths.size)

            blobs = fetch_blobs(paths)
            next_paths = paths.flat_map { |path| collect_file(path, blobs[path]) }.to_set - seen

            check_size_limit!

            seen.merge(next_paths)
            next_paths
          end

          def collect_file(path, content)
            result = IncludeFile.new(path: path, content: content, include_matcher: include_matcher).execute

            files[path] = content if content.present?
            errors.concat(result.errors)
            result.paths
          end

          # Only matches each include to its file class; nothing is fetched through it.
          def include_matcher
            @include_matcher ||= ::Gitlab::Ci::Config::External::Mapper::Matcher.new(
              ::Gitlab::Ci::Config::External::Context.new(project: project, sha: sha)
            )
          end

          def fetch_blobs(paths)
            project.repository.blobs_at(paths.map { |path| [sha, path] }).to_h { |blob| [blob.path, blob.data] }
          end

          def check_file_limit!(count)
            limit = Gitlab::CurrentSettings.ci_max_includes
            return if count <= limit

            raise CollectError, ["`#{entry_path}`: includes more than #{limit} files"]
          end

          def check_size_limit!
            limit = Gitlab::CurrentSettings.ci_max_total_yaml_size_bytes
            return if files.each_value.sum(&:bytesize) <= limit

            raise CollectError, ["`#{entry_path}`: includes more than #{limit} bytes of YAML"]
          end
        end
      end
    end
  end
end
