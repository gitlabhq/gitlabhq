# frozen_string_literal: true

class TestReportEntity < Grape::Entity
  expose :total_time, documentation: { type: 'integer', example: 180 }
  expose :total_count, documentation: { type: 'integer', example: 1 }

  expose :success_count, documentation: { type: 'integer', example: 1 }
  expose :failed_count, documentation: { type: 'integer', example: 0 }
  expose :skipped_count, documentation: { type: 'integer', example: 0 }
  expose :error_count, documentation: { type: 'integer', example: 0 }

  expose :test_suites, using: TestSuiteEntity, documentation: { is_array: true } do |report|
    report.test_suites.values
  end
end
