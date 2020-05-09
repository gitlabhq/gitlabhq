# frozen_string_literal: true

module Ci
  class CompareAccessibilityReportsService < CompareReportsBaseService
    def comparer_class
      Gitlab::Ci::Reports::AccessibilityReportsComparer
    end

    def serializer_class
      AccessibilityReportsComparerSerializer
    end

    def get_report(pipeline)
      pipeline&.accessibility_reports
    end
  end
end
