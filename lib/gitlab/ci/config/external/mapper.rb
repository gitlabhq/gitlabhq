# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Mapper
          include Gitlab::Utils::StrongMemoize

          # Will be removed with FF ci_refactoring_external_mapper
          FILE_CLASSES = [
            External::File::Local,
            External::File::Project,
            External::File::Remote,
            External::File::Template,
            External::File::Artifact
          ].freeze

          # Will be removed with FF ci_refactoring_external_mapper
          FILE_SUBKEYS = FILE_CLASSES.map { |f| f.name.demodulize.downcase }.freeze

          Error = Class.new(StandardError)
          AmbigiousSpecificationError = Class.new(Error)
          TooManyIncludesError = Class.new(Error)

          def initialize(values, context)
            @locations = Array.wrap(values.fetch(:include, [])).compact
            @context = context
          end

          def process
            return [] if @locations.empty?

            context.logger.instrument(:config_mapper_process) do
              if ::Feature.enabled?(:ci_refactoring_external_mapper, context.project)
                process_without_instrumentation
              else
                legacy_process_without_instrumentation
              end
            end
          end

          private

          attr_reader :context

          delegate :expandset, :logger, to: :context

          def process_without_instrumentation
            locations = Normalizer.new(context).process(@locations)
            locations = Filter.new(context).process(locations)
            locations = LocationExpander.new(context).process(locations)
            locations = VariablesExpander.new(context).process(locations)

            files = Matcher.new(context).process(locations)
            Verifier.new(context).process(files)

            files
          end

          # This and the following methods will be removed with FF ci_refactoring_external_mapper
          def legacy_process_without_instrumentation
            @locations
              .map(&method(:normalize_location))
              .filter_map(&method(:verify_rules))
              .flat_map(&method(:expand_project_files))
              .flat_map(&method(:expand_wildcard_paths))
              .map(&method(:expand_variables))
              .map(&method(:select_first_matching))
              .each(&method(:verify!))
          end

          # convert location if String to canonical form
          def normalize_location(location)
            if location.is_a?(String)
              expanded_location = expand_variables(location)
              normalize_location_string(expanded_location)
            else
              location.deep_symbolize_keys
            end
          end

          def verify_rules(location)
            logger.instrument(:config_mapper_rules) do
              verify_rules_without_instrumentation(location)
            end
          end

          def verify_rules_without_instrumentation(location)
            return unless Rules.new(location[:rules]).evaluate(context).pass?

            location
          end

          def expand_project_files(location)
            return location unless location[:project]

            Array.wrap(location[:file]).map do |file|
              location.merge(file: file)
            end
          end

          def expand_wildcard_paths(location)
            logger.instrument(:config_mapper_wildcards) do
              expand_wildcard_paths_without_instrumentation(location)
            end
          end

          def expand_wildcard_paths_without_instrumentation(location)
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

          def select_first_matching(location)
            logger.instrument(:config_mapper_select) do
              select_first_matching_without_instrumentation(location)
            end
          end

          def select_first_matching_without_instrumentation(location)
            matching = FILE_CLASSES.map do |file_class|
              file_class.new(location, context)
            end.select(&:matching?)

            if matching.one?
              matching.first
            elsif matching.empty?
              raise AmbigiousSpecificationError, "`#{masked_location(location.to_json)}` does not have a valid subkey for include. Valid subkeys are: `#{FILE_SUBKEYS.join('`, `')}`"
            else
              raise AmbigiousSpecificationError, "Each include must use only one of: `#{FILE_SUBKEYS.join('`, `')}`"
            end
          end

          def verify!(location_object)
            verify_max_includes!
            location_object.validate!
            expandset.add(location_object)
          end

          def verify_max_includes!
            if expandset.count >= context.max_includes
              raise TooManyIncludesError, "Maximum of #{context.max_includes} nested includes are allowed!"
            end
          end

          def expand_variables(data)
            logger.instrument(:config_mapper_variables) do
              expand_variables_without_instrumentation(data)
            end
          end

          def expand_variables_without_instrumentation(data)
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
            ExpandVariables.expand(data, -> { context.variables_hash })
          end

          def masked_location(location)
            context.mask_variables_from(location)
          end
        end
      end
    end
  end
end
