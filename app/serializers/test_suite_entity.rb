# frozen_string_literal: true

class TestSuiteEntity < Grape::Entity
  expose :name, documentation: { type: 'string', example: 'test' }
  expose :total_time, documentation: { type: 'integer', example: 1904 }
  expose :total_count, documentation: { type: 'integer', example: 3363 }

  expose :success_count, documentation: { type: 'integer', example: 3351 }
  expose :failed_count, documentation: { type: 'integer', example: 0 }
  expose :skipped_count, documentation: { type: 'integer', example: 12 }
  expose :error_count, documentation: { type: 'integer', example: 0 }

  with_options if: ->(_, opts) { opts[:details] } do |test_suite|
    expose :suite_error,
      documentation: { type: 'string', example: 'JUnit XML parsing failed: 1:1: FATAL: Document is empty' }
    expose :test_cases, using: TestCaseEntity, documentation: { is_array: true } do |test_suite|
      test_suite.suite_error ? [] : test_suite.sorted.test_cases.values.flat_map(&:values)
    end
  end
end
