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
      pipeline&.test_reports
    end
  end
end
