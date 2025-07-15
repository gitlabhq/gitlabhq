# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Report
          attr_reader :created_at, :type, :findings, :identifiers
          attr_accessor :pipeline, :scanned_resources, :errors,
            :analyzer, :version, :schema_validation_status, :warnings,
            :scan, :scanner

          delegate :project_id, to: :pipeline
          delegate :project, to: :pipeline
          delegate :primary_identifiers, to: :scanner

          def initialize(type, pipeline, created_at)
            @type = type
            @pipeline = pipeline
            @created_at = created_at
            @findings = []
            @identifiers = {}
            @scanned_resources = []
            @errors = []
            @warnings = []
          end

          def commit_sha
            pipeline.sha
          end

          def add_error(type, message = 'An unexpected error happened!')
            errors << { type: type, message: message }
          end

          def add_warning(type, message)
            warnings << { type: type, message: message }
          end

          def errored?
            errors.present?
          end

          def warnings?
            warnings.present?
          end

          def add_identifier(identifier)
            identifiers[identifier.key] ||= identifier
          end

          def add_finding(finding)
            findings << finding
          end

          def clone_as_blank
            Report.new(type, pipeline, created_at)
          end

          def replace_with!(other)
            instance_variables.each do |ivar|
              instance_variable_set(ivar, other.public_send(ivar.to_s[1..])) # rubocop:disable GitlabSecurity/PublicSend
            end
          end

          def merge!(other)
            replace_with!(::Security::MergeReportsService.new(self, other).execute)
          end

          def scanner_order_to(other)
            return 1 unless scanner
            return -1 unless other.scanner

            scanner <=> other.scanner
          end

          def has_signatures?
            findings.any?(&:has_signatures?)
          end
        end
      end
    end
  end
end
