# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class TestSuiteComparer
        include Gitlab::Utils::StrongMemoize

        DEFAULT_MAX_TESTS = 100
        DEFAULT_MIN_TESTS = 10
        TestSummary = Struct.new(:new_failures, :existing_failures, :resolved_failures, :new_errors, :existing_errors, :resolved_errors, keyword_init: true)

        attr_reader :name, :base_suite, :head_suite

        def initialize(name, base_suite, head_suite)
          @name = name
          @base_suite = base_suite || TestSuite.new
          @head_suite = head_suite
        end

        def new_failures
          strong_memoize(:new_failures) do
            head_suite.failed.reject do |key, _|
              base_suite.failed.include?(key)
            end.values
          end
        end

        def existing_failures
          strong_memoize(:existing_failures) do
            head_suite.failed.select do |key, _|
              base_suite.failed.include?(key)
            end.values
          end
        end

        def resolved_failures
          strong_memoize(:resolved_failures) do
            head_suite.success.select do |key, _|
              base_suite.failed.include?(key)
            end.values
          end
        end

        def new_errors
          strong_memoize(:new_errors) do
            head_suite.error.reject do |key, _|
              base_suite.error.include?(key)
            end.values
          end
        end

        def existing_errors
          strong_memoize(:existing_errors) do
            head_suite.error.select do |key, _|
              base_suite.error.include?(key)
            end.values
          end
        end

        def resolved_errors
          strong_memoize(:resolved_errors) do
            head_suite.success.select do |key, _|
              base_suite.error.include?(key)
            end.values
          end
        end

        def total_count
          head_suite.total_count
        end

        def total_status
          head_suite.total_status
        end

        def resolved_count
          resolved_failures.count + resolved_errors.count
        end

        def failed_count
          new_failures.count + existing_failures.count
        end

        def error_count
          new_errors.count + existing_errors.count
        end

        # This is used to limit the presented test cases but does not affect
        # total count of tests in the summary
        def limited_tests
          strong_memoize(:limited_tests) do
            # rubocop: disable CodeReuse/ActiveRecord
            TestSummary.new(
              new_failures: new_failures.take(max_tests),
              existing_failures: existing_failures.take(max_tests(new_failures)),
              resolved_failures: resolved_failures.take(max_tests(new_failures, existing_failures)),
              new_errors: new_errors.take(max_tests),
              existing_errors: existing_errors.take(max_tests(new_errors)),
              resolved_errors: resolved_errors.take(max_tests(new_errors, existing_errors))
            )
            # rubocop: enable CodeReuse/ActiveRecord
          end
        end

        private

        def max_tests(*used)
          [DEFAULT_MAX_TESTS - used.sum(&:count), DEFAULT_MIN_TESTS].max
        end
      end
    end
  end
end
