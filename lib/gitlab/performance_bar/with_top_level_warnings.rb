# frozen_string_literal: true

module Gitlab
  module PerformanceBar
    module WithTopLevelWarnings
      def results
        results = super

        results.merge(has_warnings: has_warnings?(results))
      end

      def has_warnings?(results)
        results[:data].any? do |_, value|
          value[:warnings].present?
        end
      end
    end
  end
end
