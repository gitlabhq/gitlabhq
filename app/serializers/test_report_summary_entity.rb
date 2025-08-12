# frozen_string_literal: true

class TestReportSummaryEntity < Grape::Entity
  expose :total, documentation: {
    type: 'object',
    example: {
      time: 0.42,
      count: 2,
      success: 2,
      failed: 0,
      skipped: 0,
      error: 0,
      suite_error: nil
    }
  }

  expose :test_suites, using: TestSuiteSummaryEntity do |summary|
    summary.test_suites.values
  end
end
