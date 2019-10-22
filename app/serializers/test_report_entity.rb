# frozen_string_literal: true

class TestReportEntity < Grape::Entity
  expose :total_time
  expose :total_count

  expose :success_count
  expose :failed_count
  expose :skipped_count
  expose :error_count

  expose :test_suites, using: TestSuiteEntity do |report|
    report.test_suites.values
  end
end
