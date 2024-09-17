# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Sbom
        module Validators
          class CyclonedxSchemaValidator
            SUPPORTED_SPEC_VERSIONS = %w[1.4 1.5 1.6].freeze

            SCHEMA_BASE_PATH = Rails.root.join('app', 'validators', 'json_schemas', 'cyclonedx').freeze

            def initialize(report_data)
              @report_data = report_data
            end

            def valid?
              errors.empty?
            end

            def errors
              @errors ||= validate!
            end

            private

            def validate!
              if spec_version_valid?
                pretty_errors
              else
                [format("Unsupported CycloneDX spec version. Must be one of: %{versions}",
                  versions: SUPPORTED_SPEC_VERSIONS.join(', '))]
              end
            end

            def spec_version_valid?
              SUPPORTED_SPEC_VERSIONS.include?(spec_version)
            end

            def spec_version
              @report_data['specVersion']
            end

            def raw_errors
              JSONSchemer.schema(SCHEMA_BASE_PATH.join("bom-#{spec_version}.schema.json")).validate(@report_data)
            end

            def pretty_errors
              raw_errors.map { |error| JSONSchemer::Errors.pretty(error) }
            end
          end
        end
      end
    end
  end
end
