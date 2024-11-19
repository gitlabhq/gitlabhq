# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class TestSuite
        attr_accessor :name
        attr_accessor :test_cases
        attr_accessor :total_time
        attr_reader :suite_error

        def initialize(name = nil)
          @name = name
          @test_cases = {}
          @total_time = 0.0
        end

        def add_test_case(test_case)
          @test_cases[test_case.status] ||= {}
          @test_cases[test_case.status][test_case.key] = test_case
          @total_time += test_case.execution_time
        end

        def each_test_case
          @test_cases.each do |status, test_cases|
            test_cases.values.each do |test_case|
              yield test_case
            end
          end
        end

        def total_count
          return 0 if suite_error

          [success_count, failed_count, skipped_count, error_count].sum
        end

        def total_status
          if suite_error
            TestCase::STATUS_ERROR
          elsif failed_count > 0 || error_count > 0
            TestCase::STATUS_FAILED
          else
            TestCase::STATUS_SUCCESS
          end
        end

        def with_attachment!
          @test_cases = @test_cases.extract!("failed")

          @test_cases.keep_if do |status, hash|
            hash.any? do |key, test_case|
              test_case.has_attachment?
            end
          end
        end

        TestCase::STATUS_TYPES.each do |status_type|
          define_method(status_type.to_s) do
            return {} if suite_error || test_cases[status_type].nil?

            test_cases[status_type]
          end

          define_method("#{status_type}_count") do
            return 0 if suite_error || test_cases[status_type].nil?

            test_cases[status_type].length
          end
        end

        def set_suite_error(msg)
          @suite_error = msg
        end

        def +(other)
          self.class.new.tap do |test_suite|
            test_suite.name = other.name
            test_suite.test_cases = self.test_cases.deep_merge(other.test_cases)
            test_suite.total_time = self.total_time + other.total_time
          end
        end

        def sorted
          sort_by_status
          sort_by_execution_time_desc
          self
        end

        private

        def sort_by_status
          @test_cases = @test_cases.sort_by { |status, _| Gitlab::Ci::Reports::TestCase::STATUS_TYPES.index(status) }.to_h
        end

        def sort_by_execution_time_desc
          @test_cases = @test_cases.keys.index_with do |key|
            @test_cases[key].sort_by { |_key, test_case| -test_case.execution_time }.to_h
          end
        end
      end
    end
  end
end
