# frozen_string_literal: true

module Ci
  class CompareTestReportsService < CompareReportsBaseService
    def comparer_class
      Gitlab::Ci::Reports::TestReportsComparer
    end

    def serializer_class
      TestReportsComparerSerializer
    end

    def get_report(pipeline)
      # Scope to the reports the requesting user may read; the MR widget reaches
      # this via MergeRequest#compare_test_reports(current_user), and the user is
      # part of the reactive-cache key so filtered results are not shared.
      pipeline&.accessible_test_reports(current_user)
    end

    def build_comparer(base_report, head_report)
      # We need to load the test failure history on the test comparer because we display
      # this on the MR widget
      super.tap do |test_reports_comparer|
        ::Gitlab::Ci::Reports::TestFailureHistory.new(failed_test_cases(test_reports_comparer), project).load!
      end
    end

    def failed_test_cases(test_reports_comparer)
      test_reports_comparer.suite_comparers.flat_map do |suite_comparer|
        suite_comparer.limited_tests.new_failures + suite_comparer.limited_tests.existing_failures
      end
    end
  end
end
