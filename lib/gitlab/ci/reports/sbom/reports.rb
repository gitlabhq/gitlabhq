# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Sbom
        class Reports
          attr_reader :reports

          def initialize(reports = [])
            @reports = reports
          end

          def add_report(report)
            @reports << report
          end

          def valid_reports
            reports.select(&:valid?)
          end
        end
      end
    end
  end
end
