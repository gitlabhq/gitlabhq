# frozen_string_literal: true

module WorkItems
  module Widgets
    class Development < Base
      def closing_merge_requests
        work_item.merge_requests_closing_issues
      end

      def will_auto_close_by_merge_request
        return false unless work_item.opened? && autoclose_referenced_issues_enabled?

        work_item.merge_requests_closing_issues.with_opened_merge_request.exists?
      end

      private

      def autoclose_referenced_issues_enabled?
        return true if work_item.project.nil?

        work_item.project.autoclose_referenced_issues
      end
    end
  end
end

WorkItems::Widgets::Development.prepend_mod
