# frozen_string_literal: true

class TestSuiteEntity < Grape::Entity
  expose :name
  expose :total_time
  expose :total_count

  expose :success_count
  expose :failed_count
  expose :skipped_count
  expose :error_count
  expose :suite_error

  expose :test_cases, using: TestCaseEntity do |test_suite|
    test_suite.suite_error ? [] : test_suite.test_cases.values.flat_map(&:values)
  end
end
