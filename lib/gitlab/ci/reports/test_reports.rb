module Gitlab
  module Ci
    module Reports
      class TestReports
        attr_reader :test_suites

        def initialize
          @test_suites = {}
        end

        def get_suite(suite_name)
          test_suites[suite_name] ||= TestSuite.new(suite_name)
        end

        def total_time
          test_suites.values.sum(&:total_time)
        end

        def total_count
          test_suites.values.sum(&:total_count)
        end

        def total_status
          if failed_count > 0 || error_count > 0
            TestCase::STATUS_FAILED
          else
            TestCase::STATUS_SUCCESS
          end
        end

        TestCase::STATUS_TYPES.each do |status_type|
          define_method("#{status_type}_count") do
            test_suites.values.sum { |suite| suite.public_send("#{status_type}_count") } # rubocop:disable GitlabSecurity/PublicSend
          end
        end
      end
    end
  end
end
