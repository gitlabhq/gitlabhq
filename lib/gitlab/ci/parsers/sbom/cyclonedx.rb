# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Sbom
        class Cyclonedx
          SUPPORTED_SPEC_VERSIONS = %w[1.4].freeze
          COMPONENT_ATTRIBUTES = %w[type name version].freeze

          def initialize(json_data, report)
            @json_data = json_data
            @report = report
          end

          def parse!
            @data = Gitlab::Json.parse(json_data)

            return unless valid?

            parse_report
          rescue JSON::ParserError => e
            report.add_error("Report JSON is invalid: #{e}")
          end

          private

          attr_reader :json_data, :report, :data

          def schema_validator
            @schema_validator ||= Validators::CyclonedxSchemaValidator.new(data)
          end

          def valid?
            valid_schema? && supported_spec_version?
          end

          def supported_spec_version?
            return true if SUPPORTED_SPEC_VERSIONS.include?(data['specVersion'])

            report.add_error(
              "Unsupported CycloneDX spec version. Must be one of: %{versions}" \
              % { versions: SUPPORTED_SPEC_VERSIONS.join(', ') }
            )

            false
          end

          def valid_schema?
            return true if schema_validator.valid?

            schema_validator.errors.each { |error| report.add_error(error) }

            false
          end

          def parse_report
            parse_metadata_properties
            parse_components
          end

          def parse_metadata_properties
            properties = data.dig('metadata', 'properties')
            source = CyclonedxProperties.parse_source(properties)
            report.set_source(source) if source
          end

          def parse_components
            data['components']&.each do |component|
              next unless supported_component_type?(component['type'])

              report.add_component(component.slice(*COMPONENT_ATTRIBUTES))
            end
          end

          def supported_component_type?(type)
            ::Enums::Sbom.component_types.include?(type.to_sym)
          end
        end
      end
    end
  end
end
