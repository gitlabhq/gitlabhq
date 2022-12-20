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
        end
      end
    end
  end
end

Gitlab::Ci::Reports::Security::Reports.prepend_mod_with('Gitlab::Ci::Reports::Security::Reports')
