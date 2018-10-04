module Gitlab
  module Ci
    module Reports
      class TestSuite
        attr_reader :name
        attr_reader :test_cases
        attr_reader :total_time

        def initialize(name = nil)
          @name = name
          @test_cases = {}
          @total_time = 0.0
          @duplicate_cases = []
        end

        def add_test_case(test_case)
          @duplicate_cases << test_case if existing_key?(test_case)

          @test_cases[test_case.status] ||= {}
          @test_cases[test_case.status][test_case.key] = test_case
          @total_time += test_case.execution_time
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def total_count
          test_cases.values.sum(&:count)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def total_status
          if failed_count > 0 || error_count > 0
            TestCase::STATUS_FAILED
          else
            TestCase::STATUS_SUCCESS
          end
        end

        TestCase::STATUS_TYPES.each do |status_type|
          define_method("#{status_type}") do
            test_cases[status_type] || {}
          end

          define_method("#{status_type}_count") do
            test_cases[status_type]&.length.to_i
          end
        end

        private

        def existing_key?(test_case)
          @test_cases[test_case.status]&.key?(test_case.key)
        end
      end
    end
  end
end
