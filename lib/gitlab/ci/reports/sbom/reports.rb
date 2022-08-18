# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Sbom
        class Reports
          attr_reader :reports

          def initialize
            @reports = []
          end

          def add_report(report)
            @reports << report
          end
        end
      end
    end
  end
end
