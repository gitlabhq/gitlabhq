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
      pipeline&.accessible_accessibility_reports(current_user)
    end
  end
end
