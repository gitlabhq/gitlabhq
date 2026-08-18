# frozen_string_literal: true

module WorkItems
  module Widgets
    class Development < Base
      def self.quick_action_commands
        [:create_merge_request]
      end

      def self.quick_action_params
        [:branch_name]
      end

      def closing_merge_requests
        work_item.merge_request_closing_issues
      end

      def will_auto_close_by_merge_request
        return false unless work_item.eligible_for_autoclose_by_merge_request?

        work_item.merge_request_closing_issues.with_opened_merge_request.exists?
      end
    end
  end
end

WorkItems::Widgets::Development.prepend_mod
