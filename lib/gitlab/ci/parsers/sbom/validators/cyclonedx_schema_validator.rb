# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Sbom
        module Validators
          class CyclonedxSchemaValidator
            SCHEMA_PATH = Rails.root.join('app', 'validators', 'json_schemas', 'cyclonedx_report.json').freeze

            def initialize(report_data)
              @report_data = report_data
            end

            def valid?
              errors.empty?
            end

            def errors
              @errors ||= pretty_errors
            end

            private

            def raw_errors
              JSONSchemer.schema(SCHEMA_PATH).validate(@report_data)
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
