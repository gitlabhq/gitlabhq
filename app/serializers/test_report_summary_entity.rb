# frozen_string_literal: true

class TestReportSummaryEntity < TestReportEntity
  expose :test_suites, using: TestSuiteSummaryEntity do |summary|
    summary.test_suites.values
  end
end
