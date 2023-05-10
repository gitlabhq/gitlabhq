# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        module Validators
          class SchemaValidator
            SUPPORTED_VERSIONS = {
              cluster_image_scanning: %w[15.0.0 15.0.1 15.0.2 15.0.4 15.0.6],
              container_scanning: %w[15.0.0 15.0.1 15.0.2 15.0.4 15.0.6],
              coverage_fuzzing: %w[15.0.0 15.0.1 15.0.2 15.0.4 15.0.6],
              dast: %w[15.0.0 15.0.1 15.0.2 15.0.4 15.0.6],
              api_fuzzing: %w[15.0.0 15.0.1 15.0.2 15.0.4 15.0.6],
              dependency_scanning: %w[15.0.0 15.0.1 15.0.2 15.0.4 15.0.6],
              sast: %w[15.0.0 15.0.1 15.0.2 15.0.4 15.0.6],
              secret_detection: %w[15.0.0 15.0.1 15.0.2 15.0.4 15.0.6]
            }.freeze

            VERSIONS_TO_REMOVE_IN_17_0 = %w[].freeze

            DEPRECATED_VERSIONS = {
              cluster_image_scanning: VERSIONS_TO_REMOVE_IN_17_0,
              container_scanning: VERSIONS_TO_REMOVE_IN_17_0,
              coverage_fuzzing: VERSIONS_TO_REMOVE_IN_17_0,
              dast: VERSIONS_TO_REMOVE_IN_17_0,
              api_fuzzing: VERSIONS_TO_REMOVE_IN_17_0,
              dependency_scanning: VERSIONS_TO_REMOVE_IN_17_0,
              sast: VERSIONS_TO_REMOVE_IN_17_0,
              secret_detection: VERSIONS_TO_REMOVE_IN_17_0
            }.freeze

            CURRENT_VERSIONS = SUPPORTED_VERSIONS.to_h { |k, v| [k, v - DEPRECATED_VERSIONS[k]] }

            class Schema
              def root_path
                File.join(__dir__, 'schemas')
              end

              def initialize(report_type, report_version)
                @report_type = report_type.to_sym
                @report_version = report_version.to_s
                @supported_versions = SUPPORTED_VERSIONS[@report_type]
              end

              delegate :validate, to: :schemer

              private

              attr_reader :report_type, :report_version, :supported_versions

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

                if latest_vendored_patch_version
                  latest_vendored_patch_version_file = File.join(root_path, latest_vendored_patch_version, file_name)
                  return latest_vendored_patch_version_file if File.file?(latest_vendored_patch_version_file)
                end

                earliest_supported_version = SUPPORTED_VERSIONS[report_type].min
                File.join(root_path, earliest_supported_version, file_name)
              end

              def latest_vendored_patch_version
                ::Security::ReportSchemaVersionMatcher.new(
                  report_declared_version: report_version,
                  supported_versions: supported_versions
                ).call
              rescue ArgumentError
                nil
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

              populate_schema_version_errors
              populate_validation_errors
              populate_deprecation_warnings
            end

            def populate_schema_version_errors
              add_schema_version_errors if add_schema_version_error?
            end

            def add_schema_version_errors
              if report_version.nil?
                template = _("Report version not provided,"\
                " %{report_type} report type supports versions: %{supported_schema_versions}."\
                " GitLab will attempt to validate this report against the earliest supported versions of this report"\
                " type, to show all the errors but will not ingest the report")
                message = format(template, report_type: report_type, supported_schema_versions: supported_schema_versions)
              else
                template = _("Version %{report_version} for report type %{report_type} is unsupported, supported versions"\
                " for this report type are: %{supported_schema_versions}."\
                " GitLab will attempt to validate this report against the earliest supported versions of this report"\
                " type, to show all the errors but will not ingest the report")
                message = format(template, report_version: report_version, report_type: report_type, supported_schema_versions: supported_schema_versions)
              end

              log_warnings(problem_type: 'using_unsupported_schema_version')
              add_message_as(level: :error, message: message)
            end

            def add_schema_version_error?
              !report_uses_supported_schema_version? &&
                !report_uses_deprecated_schema_version? &&
                !report_uses_supported_major_and_minor_schema_version?
            end

            def report_uses_deprecated_schema_version?
              # Avoid deprecation warnings for GitLab security scanners
              # To be removed via https://gitlab.com/gitlab-org/gitlab/-/issues/386798
              return if report_data.dig('scan', 'scanner', 'vendor', 'name')&.downcase == 'gitlab'
              return if report_data.dig('scan', 'analyzer', 'vendor', 'name')&.downcase == 'gitlab'

              DEPRECATED_VERSIONS[report_type].include?(report_version)
            end

            def report_uses_supported_schema_version?
              SUPPORTED_VERSIONS[report_type].include?(report_version)
            end

            def report_uses_supported_major_and_minor_schema_version?
              if !find_latest_patch_version.nil?
                add_supported_major_minor_behavior_warning
                true
              else
                false
              end
            end

            def find_latest_patch_version
              ::Security::ReportSchemaVersionMatcher.new(
                report_declared_version: report_version,
                supported_versions: SUPPORTED_VERSIONS[report_type]
              ).call
            rescue ArgumentError
              nil
            end

            def add_supported_major_minor_behavior_warning
              template = _("This report uses a supported MAJOR.MINOR schema version but the PATCH version doesn't match"\
                " any vendored schema version. Validation will be attempted against version"\
                " %{find_latest_patch_version}")

              message = format(template, find_latest_patch_version: find_latest_patch_version)

              add_message_as(
                level: :warning,
                message: message
              )
            end

            def populate_validation_errors
              schema_validation_errors = schema.validate(report_data).map { |error| JSONSchemer::Errors.pretty(error) }

              log_warnings(problem_type: 'schema_validation_fails') unless schema_validation_errors.empty?

              @errors += schema_validation_errors
            end

            def populate_deprecation_warnings
              add_deprecated_report_version_message if report_uses_deprecated_schema_version?
            end

            def add_deprecated_report_version_message
              log_warnings(problem_type: 'using_deprecated_schema_version')

              template = _("version %{report_version} for report type %{report_type} is deprecated. "\
              "However, GitLab will still attempt to parse and ingest this report. "\
              "Upgrade the security report to one of the following versions: %{current_schema_versions}.")

              message = format(
                template,
                report_version: report_version,
                report_type: report_type,
                current_schema_versions: current_schema_versions)

              add_message_as(level: :deprecation_warning, message: message)
            end

            def valid?
              errors.empty?
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

            def current_schema_versions
              CURRENT_VERSIONS[report_type].join(", ")
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
