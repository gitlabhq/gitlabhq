# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Mapper
          include Gitlab::Utils::StrongMemoize

          MAX_INCLUDES = 100

          FILE_CLASSES = [
            External::File::Remote,
            External::File::Template,
            External::File::Local,
            External::File::Project,
            External::File::Artifact
          ].freeze

          Error = Class.new(StandardError)
          AmbigiousSpecificationError = Class.new(Error)
          DuplicateIncludesError = Class.new(Error)
          TooManyIncludesError = Class.new(Error)

          def initialize(values, context)
            @locations = Array.wrap(values.fetch(:include, []))
            @context = context
          end

          def process
            return [] if locations.empty?

            locations
              .compact
              .map(&method(:normalize_location))
              .flat_map(&method(:expand_project_files))
              .flat_map(&method(:expand_wildcard_paths))
              .map(&method(:expand_variables))
              .each(&method(:verify_duplicates!))
              .map(&method(:select_first_matching))
          end

          private

          attr_reader :locations, :context

          delegate :expandset, to: :context

          # convert location if String to canonical form
          def normalize_location(location)
            if location.is_a?(String)
              expanded_location = expand_variables(location)
              normalize_location_string(expanded_location)
            else
              location.deep_symbolize_keys
            end
          end

          def expand_project_files(location)
            return location unless location[:project]

            Array.wrap(location[:file]).map do |file|
              location.merge(file: file)
            end
          end

          def expand_wildcard_paths(location)
            return location unless ::Feature.enabled?(:ci_wildcard_file_paths, context.project, default_enabled: :yaml)

            # We only support local files for wildcard paths
            return location unless location[:local] && location[:local].include?('*')

            context.project.repository.search_files_by_wildcard_path(location[:local], context.sha).map do |path|
              { local: path }
            end
          end

          def normalize_location_string(location)
            if ::Gitlab::UrlSanitizer.valid?(location)
              { remote: location }
            else
              { local: location }
            end
          end

          def verify_duplicates!(location)
            if expandset.count >= MAX_INCLUDES
              raise TooManyIncludesError, "Maximum of #{MAX_INCLUDES} nested includes are allowed!"
            end

            # We scope location to context, as this allows us to properly support
            # relative includes, and similarly looking relative in another project
            # does not trigger duplicate error
            scoped_location = location.merge(
              context_project: context.project,
              context_sha: context.sha)

            unless expandset.add?(scoped_location)
              raise DuplicateIncludesError, "Include `#{location.to_json}` was already included!"
            end
          end

          def select_first_matching(location)
            matching = FILE_CLASSES.map do |file_class|
              file_class.new(location, context)
            end.select(&:matching?)

            raise AmbigiousSpecificationError, "Include `#{location.to_json}` needs to match exactly one accessor!" unless matching.one?

            matching.first
          end

          def expand_variables(data)
            if data.is_a?(String)
              expand(data)
            else
              transform(data)
            end
          end

          def transform(data)
            data.transform_values do |values|
              case values
              when Array
                values.map { |value| expand(value.to_s) }
              when String
                expand(values)
              else
                values
              end
            end
          end

          def expand(data)
            ExpandVariables.expand(data, context.variables)
          end
        end
      end
    end
  end
end
