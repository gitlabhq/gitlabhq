# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Mapper
          # Expands locations to include all files matching the pattern
          class LocationExpander < Base
            private

            def process_without_instrumentation(locations)
              locations.flat_map do |location|
                if location[:project]
                  expand_project_files(location)
                elsif location[:local]
                  expand_wildcard_paths(location)
                else
                  location
                end
              end
            end

            def expand_project_files(location)
              Array.wrap(location[:file]).map do |file|
                location.merge(file: file)
              end
            end

            def expand_wildcard_paths(location)
              return location unless location[:local].include?('*')

              # Remove leading slashes to match repository path format, consistent
              # with how File::Local normalizes paths in its initializer.
              normalized_path = Gitlab::Utils.remove_leading_slashes(location[:local])
              paths = context.project.repository.search_files_by_wildcard_path(normalized_path, context.sha)

              parent_file = context.parent_file

              paths.filter_map do |path|
                # Prevent self-inclusion: skip paths matching the parent file that triggered this wildcard expansion.
                next if parent_file &&
                  parent_file.is_a?(Gitlab::Ci::Config::External::File::Local) &&
                  parent_file.location == path &&
                  parent_file.context.project == context.project

                location.merge(local: path)
              end
            end
          end
        end
      end
    end
  end
end
