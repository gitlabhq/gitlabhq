# frozen_string_literal: true

module Ci
  class CompareCodequalityReportsService < CompareReportsBaseService
    def comparer_class
      Gitlab::Ci::Reports::CodequalityReportsComparer
    end

    def serializer_class
      CodequalityReportsComparerSerializer
    end

    def get_report(pipeline)
      pipeline&.codequality_reports
    end
  end
end
