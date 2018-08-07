module Gitlab
  module Ci
    module Reports
      class TestSuiteComparer
        include Gitlab::Utils::StrongMemoize

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

        def total_count
          head_suite.total_count
        end

        def total_status
          head_suite.total_status
        end

        def resolved_count
          resolved_failures.count
        end

        def failed_count
          new_failures.count + existing_failures.count
        end
      end
    end
  end
end
