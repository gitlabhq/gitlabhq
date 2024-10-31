# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class TestReport
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

        def with_attachment!
          @test_suites.keep_if do |_job_name, test_suite|
            test_suite.with_attachment!.present?
          end

          self
        end

        def suite_errors
          test_suites.transform_values(&:suite_error).compact
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
