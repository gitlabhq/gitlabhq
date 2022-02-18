# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        module Validators
          class SchemaValidator
            # https://docs.gitlab.com/ee/update/deprecations.html#147
            SUPPORTED_VERSIONS = {
              cluster_image_scanning: %w[14.0.4 14.0.5 14.0.6 14.1.0],
              container_scanning: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0],
              coverage_fuzzing: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0],
              dast: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0],
              api_fuzzing: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0],
              dependency_scanning: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0],
              sast: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0],
              secret_detection: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0]
            }.freeze

            # https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/tags
            PREVIOUS_RELEASES = %w[10.0.0 12.0.0 12.1.0 13.0.0
                                   13.1.0 2.3.0-rc1 2.3.0-rc1 2.3.1-rc1 2.3.2-rc1 2.3.3-rc1
                                   2.4.0-rc1 3.0.0 3.0.0-rc1 3.1.0-rc1 4.0.0-rc1 5.0.0-rc1
                                   5.0.1-rc1 6.0.0-rc1 6.0.1-rc1 6.1.0-rc1 7.0.0-rc1 7.0.1-rc1
                                   8.0.0-rc1 8.0.1-rc1 8.1.0-rc1 9.0.0-rc1].freeze

            # These come from https://app.periscopedata.com/app/gitlab/895813/Secure-Scan-metrics?widget=12248944&udv=1385516
            KNOWN_VERSIONS_TO_DEPRECATE = %w[0.1 1.0 1.0.0 1.2 1.3 10.0.0 12.1.0 13.1.0 2.0 2.1 2.1.0 2.3 2.3.0 2.4 3.0 3.0.0 3.0.6 3.13.2 V2.7.0].freeze

            VERSIONS_TO_DEPRECATE_IN_15_0 = (PREVIOUS_RELEASES + KNOWN_VERSIONS_TO_DEPRECATE).freeze

            DEPRECATED_VERSIONS = {
              cluster_image_scanning: VERSIONS_TO_DEPRECATE_IN_15_0,
              container_scanning: VERSIONS_TO_DEPRECATE_IN_15_0,
              coverage_fuzzing: VERSIONS_TO_DEPRECATE_IN_15_0,
              dast: VERSIONS_TO_DEPRECATE_IN_15_0,
              api_fuzzing: VERSIONS_TO_DEPRECATE_IN_15_0,
              dependency_scanning: VERSIONS_TO_DEPRECATE_IN_15_0,
              sast: VERSIONS_TO_DEPRECATE_IN_15_0,
              secret_detection: VERSIONS_TO_DEPRECATE_IN_15_0
            }.freeze

            class Schema
              def root_path
                File.join(__dir__, 'schemas')
              end

              def initialize(report_type)
                @report_type = report_type.to_sym
              end

              delegate :validate, to: :schemer

              private

              attr_reader :report_type

              def schemer
                JSONSchemer.schema(pathname)
              end

              def pathname
                Pathname.new(schema_path)
              end

              def schema_path
                File.join(root_path, file_name)
              end

              def file_name
                report_type == :api_fuzzing ? "dast-report-format.json" : "#{report_type.to_s.dasherize}-report-format.json"
              end
            end

            def initialize(report_type, report_data)
              @report_type = report_type
              @report_data = report_data
            end

            def valid?
              errors.empty?
            end

            def errors
              @errors ||= schema.validate(report_data).map { |error| JSONSchemer::Errors.pretty(error) }
            end

            private

            attr_reader :report_type, :report_data

            def schema
              Schema.new(report_type)
            end
          end
        end
      end
    end
  end
end

Gitlab::Ci::Parsers::Security::Validators::SchemaValidator::Schema.prepend_mod_with("Gitlab::Ci::Parsers::Security::Validators::SchemaValidator::Schema")
