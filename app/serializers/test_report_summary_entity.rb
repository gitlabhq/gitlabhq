# frozen_string_literal: true

class TestReportSummaryEntity < Grape::Entity
  expose :total

  expose :test_suites, using: TestSuiteSummaryEntity do |summary|
    summary.test_suites.values
  end
end
