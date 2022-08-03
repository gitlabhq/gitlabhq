# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        module Validators
          class SchemaValidator
            SUPPORTED_VERSIONS = {
              cluster_image_scanning: %w[14.0.4 14.0.5 14.0.6 14.1.0 14.1.1 14.1.2],
              container_scanning: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0 14.1.1 14.1.2],
              coverage_fuzzing: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0 14.1.1 14.1.2],
              dast: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0 14.1.1 14.1.2],
              api_fuzzing: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0 14.1.1 14.1.2],
              dependency_scanning: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0 14.1.1 14.1.2],
              sast: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0 14.1.1 14.1.2],
              secret_detection: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0 14.1.1 14.1.2]
            }.freeze

            VERSIONS_TO_REMOVE_IN_16_0 = [].freeze

            DEPRECATED_VERSIONS = {
              cluster_image_scanning: VERSIONS_TO_REMOVE_IN_16_0,
              container_scanning: VERSIONS_TO_REMOVE_IN_16_0,
              coverage_fuzzing: VERSIONS_TO_REMOVE_IN_16_0,
              dast: VERSIONS_TO_REMOVE_IN_16_0,
              api_fuzzing: VERSIONS_TO_REMOVE_IN_16_0,
              dependency_scanning: VERSIONS_TO_REMOVE_IN_16_0,
              sast: VERSIONS_TO_REMOVE_IN_16_0,
              secret_detection: VERSIONS_TO_REMOVE_IN_16_0
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
                # The schema version selection logic here is described in the user documentation:
                # https://docs.gitlab.com/ee/user/application_security/#security-report-validation
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

              @errors += schema_validation_errors
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

              handle_unsupported_report_version
            end

            def report_uses_deprecated_schema_version?
              DEPRECATED_VERSIONS[report_type].include?(report_version)
            end

            def report_uses_supported_schema_version?
              SUPPORTED_VERSIONS[report_type].include?(report_version)
            end

            def handle_unsupported_report_version
              if report_version.nil?
                message = "Report version not provided, #{report_type} report type supports versions: #{supported_schema_versions}"
              else
                message = "Version #{report_version} for report type #{report_type} is unsupported, supported versions for this report type are: #{supported_schema_versions}"
              end

              add_message_as(level: :error, message: message)
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
