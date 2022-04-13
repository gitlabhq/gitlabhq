# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        module Validators
          class SchemaValidator
            # https://docs.gitlab.com/ee/update/deprecations.html#147
            SUPPORTED_VERSIONS = {
              cluster_image_scanning: %w[14.0.4 14.0.5 14.0.6 14.1.0 14.1.1],
              container_scanning: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0 14.1.1],
              coverage_fuzzing: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0 14.1.1],
              dast: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0 14.1.1],
              api_fuzzing: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0 14.1.1],
              dependency_scanning: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0 14.1.1],
              sast: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0 14.1.1],
              secret_detection: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0 14.1.1]
            }.freeze

            # https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/tags
            PREVIOUS_RELEASES = %w[10.0.0 12.0.0 12.1.0 13.0.0
                                   13.1.0 2.3.0-rc1 2.3.0-rc1 2.3.1-rc1 2.3.2-rc1 2.3.3-rc1
                                   2.4.0-rc1 3.0.0 3.0.0-rc1 3.1.0-rc1 4.0.0-rc1 5.0.0-rc1
                                   5.0.1-rc1 6.0.0-rc1 6.0.1-rc1 6.1.0-rc1 7.0.0-rc1 7.0.1-rc1
                                   8.0.0-rc1 8.0.1-rc1 8.1.0-rc1 9.0.0-rc1].freeze

            # These come from https://app.periscopedata.com/app/gitlab/895813/Secure-Scan-metrics?widget=12248944&udv=1385516
            KNOWN_VERSIONS_TO_REMOVE = %w[0.1 1.0 1.0.0 1.2 1.3 10.0.0 12.1.0 13.1.0 2.0 2.1 2.1.0 2.3 2.3.0 2.4 3.0 3.0.0 3.0.6 3.13.2 V2.7.0].freeze

            VERSIONS_TO_REMOVE_IN_15_0 = (PREVIOUS_RELEASES + KNOWN_VERSIONS_TO_REMOVE).freeze

            DEPRECATED_VERSIONS = {
              cluster_image_scanning: VERSIONS_TO_REMOVE_IN_15_0,
              container_scanning: VERSIONS_TO_REMOVE_IN_15_0,
              coverage_fuzzing: VERSIONS_TO_REMOVE_IN_15_0,
              dast: VERSIONS_TO_REMOVE_IN_15_0,
              api_fuzzing: VERSIONS_TO_REMOVE_IN_15_0,
              dependency_scanning: VERSIONS_TO_REMOVE_IN_15_0,
              sast: VERSIONS_TO_REMOVE_IN_15_0,
              secret_detection: VERSIONS_TO_REMOVE_IN_15_0
            }.freeze

            class Schema
              def root_path
                File.join(__dir__, 'schemas')
              end

              def initialize(report_type, report_version)
                @report_type = report_type.to_sym
                @report_version = report_version.to_s
              end

              delegate :validate, to: :schemer

              private

              attr_reader :report_type, :report_version

              def schemer
                JSONSchemer.schema(pathname)
              end

              def pathname
                Pathname.new(schema_path)
              end

              def schema_path
                # We can't exactly error out here pre-15.0.
                # If the report itself doesn't specify the schema version,
                # it will be considered invalid post-15.0 but for now we will
                # validate against earliest supported version.
                # https://gitlab.com/gitlab-org/gitlab/-/issues/335789#note_801479803
                # describes the indended behavior in detail
                # TODO: After 15.0 - pass report_type and report_data here and
                # error out if no version.
                report_declared_version = File.join(root_path, report_version, file_name)
                return report_declared_version if File.file?(report_declared_version)

                earliest_supported_version = SUPPORTED_VERSIONS[report_type].min
                File.join(root_path, earliest_supported_version, file_name)
              end

              def file_name
                report_type == :api_fuzzing ? "dast-report-format.json" : "#{report_type.to_s.dasherize}-report-format.json"
              end
            end

            def initialize(report_type, report_data, report_version = nil, project: nil, scanner: nil)
              @report_type = report_type&.to_sym
              @report_data = report_data
              @report_version = report_version
              @project = project
              @scanner = scanner
              @errors = []
              @warnings = []
              @deprecation_warnings = []

              populate_errors
              populate_warnings
              populate_deprecation_warnings
            end

            def valid?
              errors.empty?
            end

            def populate_errors
              schema_validation_errors = schema.validate(report_data).map { |error| JSONSchemer::Errors.pretty(error) }

              log_warnings(problem_type: 'schema_validation_fails') unless schema_validation_errors.empty?

              if Feature.enabled?(:enforce_security_report_validation, @project)
                @errors += schema_validation_errors
              else
                @warnings += schema_validation_errors
              end
            end

            def populate_warnings
              add_unsupported_report_version_message if !report_uses_supported_schema_version? && !report_uses_deprecated_schema_version?
            end

            def populate_deprecation_warnings
              add_deprecated_report_version_message if report_uses_deprecated_schema_version?
            end

            def add_deprecated_report_version_message
              log_warnings(problem_type: 'using_deprecated_schema_version')

              message = "Version #{report_version} for report type #{report_type} has been deprecated, supported versions for this report type are: #{supported_schema_versions}"
              add_message_as(level: :deprecation_warning, message: message)
            end

            def log_warnings(problem_type:)
              Gitlab::AppLogger.info(
                message: 'security report schema validation problem',
                security_report_type: report_type,
                security_report_version: report_version,
                project_id: @project.id,
                security_report_failure: problem_type,
                security_report_scanner_id: @scanner&.dig('id'),
                security_report_scanner_version: @scanner&.dig('version')
              )
            end

            def add_unsupported_report_version_message
              log_warnings(problem_type: 'using_unsupported_schema_version')

              if Feature.enabled?(:enforce_security_report_validation, @project)
                handle_unsupported_report_version(treat_as: :error)
              else
                handle_unsupported_report_version(treat_as: :warning)
              end
            end

            def report_uses_deprecated_schema_version?
              DEPRECATED_VERSIONS[report_type].include?(report_version)
            end

            def report_uses_supported_schema_version?
              SUPPORTED_VERSIONS[report_type].include?(report_version)
            end

            def handle_unsupported_report_version(treat_as:)
              if report_version.nil?
                message = "Report version not provided, #{report_type} report type supports versions: #{supported_schema_versions}"
                add_message_as(level: treat_as, message: message)
              else
                message = "Version #{report_version} for report type #{report_type} is unsupported, supported versions for this report type are: #{supported_schema_versions}"
              end

              add_message_as(level: treat_as, message: message)
            end

            def supported_schema_versions
              SUPPORTED_VERSIONS[report_type].join(", ")
            end

            def add_message_as(level:, message:)
              case level
              when :deprecation_warning
                @deprecation_warnings << message
              when :error
                @errors << message
              when :warning
                @warnings << message
              end
            end

            attr_reader :errors, :warnings, :deprecation_warnings

            private

            attr_reader :report_type, :report_data, :report_version

            def schema
              Schema.new(report_type, report_version)
            end
          end
        end
      end
    end
  end
end

Gitlab::Ci::Parsers::Security::Validators::SchemaValidator::Schema.prepend_mod_with("Gitlab::Ci::Parsers::Security::Validators::SchemaValidator::Schema")
