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

              context.project.repository.search_files_by_wildcard_path(location[:local], context.sha).map do |path|
                { local: path }
              end
            end
          end
        end
      end
    end
  end
end
