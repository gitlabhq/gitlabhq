# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Reports
          attr_reader :reports, :pipeline

          delegate :each, :empty?, to: :reports

          def initialize(pipeline)
            @reports = {}
            @pipeline = pipeline
          end

          def get_report(report_type, report_artifact)
            reports[report_type] ||= Report.new(report_type, pipeline, report_artifact.created_at)
          end

          def findings
            reports.values.flat_map(&:findings)
          end

          def violates_default_policy_against?(target_reports, vulnerabilities_allowed, severity_levels)
            unsafe_findings_count(target_reports, severity_levels) > vulnerabilities_allowed
          end

          private

          def findings_diff(target_reports)
            findings - target_reports&.findings.to_a
          end

          def unsafe_findings_count(target_reports, severity_levels)
            findings_diff(target_reports).count {|finding| finding.unsafe?(severity_levels)}
          end
        end
      end
    end
  end
end
