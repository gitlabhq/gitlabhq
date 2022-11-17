# frozen_string_literal: true

class TestReportSummaryEntity < Grape::Entity
  expose :total, documentation: { type: 'integer', example: 3363 }

  expose :test_suites, using: TestSuiteSummaryEntity do |summary|
    summary.test_suites.values
  end
end
