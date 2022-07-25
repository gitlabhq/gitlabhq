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

            return unless supported_spec_version?

            parse_components
          rescue JSON::ParserError => e
            report.add_error("Report JSON is invalid: #{e}")
          end

          private

          attr_reader :json_data, :report, :data

          def supported_spec_version?
            return true if SUPPORTED_SPEC_VERSIONS.include?(data['specVersion'])

            report.add_error(
              "Unsupported CycloneDX spec version. Must be one of: %{versions}" \
              % { versions: SUPPORTED_SPEC_VERSIONS.join(', ') }
            )

            false
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
