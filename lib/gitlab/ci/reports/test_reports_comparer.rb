# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class TestReportsComparer
        include Gitlab::Utils::StrongMemoize

        attr_reader :base_reports, :head_reports

        def initialize(base_reports, head_reports)
          @base_reports = base_reports || TestReport.new
          @head_reports = head_reports
        end

        def suite_comparers
          strong_memoize(:suite_comparers) do
            head_reports.test_suites.map do |name, test_suite|
              TestSuiteComparer.new(name, base_reports.get_suite(name), test_suite)
            end
          end
        end

        def total_status
          if suite_comparers.any? { |suite| suite.total_status == TestCase::STATUS_FAILED }
            TestCase::STATUS_FAILED
          else
            TestCase::STATUS_SUCCESS
          end
        end

        %w[total_count resolved_count failed_count error_count].each do |method|
          define_method(method) do
            suite_comparers.sum { |suite| suite.public_send(method) } # rubocop:disable GitlabSecurity/PublicSend
          end
        end
      end
    end
  end
end
