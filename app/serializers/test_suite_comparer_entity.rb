# frozen_string_literal: true

class TestSuiteComparerEntity < Grape::Entity
  DEFAULT_MAX_TESTS = 100
  DEFAULT_MIN_TESTS = 10

  expose :name
  expose :total_status, as: :status

  expose :summary do
    expose :total_count, as: :total
    expose :resolved_count, as: :resolved
    expose :failed_count, as: :failed
  end

  # rubocop: disable CodeReuse/ActiveRecord
  expose :new_failures, using: TestCaseEntity do |suite|
    suite.new_failures.take(max_tests)
  end

  expose :existing_failures, using: TestCaseEntity do |suite|
    suite.existing_failures.take(
      max_tests(suite.new_failures))
  end

  expose :resolved_failures, using: TestCaseEntity do |suite|
    suite.resolved_failures.take(
      max_tests(suite.new_failures, suite.existing_failures))
  end

  private

  def max_tests(*used)
    return Integer::MAX unless Feature.enabled?(:ci_limit_test_reports_size, default_enabled: true)

    [DEFAULT_MAX_TESTS - used.map(&:count).sum, DEFAULT_MIN_TESTS].max
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
