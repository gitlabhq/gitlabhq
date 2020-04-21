# frozen_string_literal: true

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

        # rubocop: disable CodeReuse/ActiveRecord
        def total_time
          test_suites.values.sum(&:total_time)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def total_count
          test_suites.values.sum(&:total_count)
        end
        # rubocop: enable CodeReuse/ActiveRecord

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
          test_suites.each_with_object({}) do |(name, suite), errors|
            errors[suite.name] = suite.suite_error if suite.suite_error
          end
        end

        TestCase::STATUS_TYPES.each do |status_type|
          define_method("#{status_type}_count") do
            # rubocop: disable CodeReuse/ActiveRecord
            test_suites.values.sum { |suite| suite.public_send("#{status_type}_count") } # rubocop:disable GitlabSecurity/PublicSend
            # rubocop: enable CodeReuse/ActiveRecord
          end
        end
      end
    end
  end
end
