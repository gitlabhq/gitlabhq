# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Report
          attr_reader :created_at, :type, :findings, :scans, :scanners, :identifiers
          attr_accessor :pipeline, :scanned_resources, :errors,
            :analyzer, :version, :schema_validation_status, :warnings

          delegate :project_id, to: :pipeline
          delegate :project, to: :pipeline

          def initialize(type, pipeline, created_at)
            @type = type
            @pipeline = pipeline
            @created_at = created_at
            @findings = []
            @scans = {}
            @scanners = {}
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

          def add_scan(scan)
            scans[scan.start_time] ||= scan
          end

          def add_scanner(scanner)
            scanners[scanner.key] ||= scanner
          end

          def scan
            scans.first&.last
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

          def primary_identifiers
            scanners.values.flat_map(&:primary_identifiers).compact
          end

          def primary_scanner
            scanners.first&.second
          end

          def primary_scanner_order_to(other)
            return 1 unless primary_scanner
            return -1 unless other.primary_scanner

            primary_scanner <=> other.primary_scanner
          end

          def has_signatures?
            findings.any?(&:has_signatures?)
          end
        end
      end
    end
  end
end
