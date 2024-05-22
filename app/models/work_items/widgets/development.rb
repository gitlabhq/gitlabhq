# frozen_string_literal: true

module WorkItems
  module Widgets
    class Development < Base
      def closing_merge_requests
        work_item.merge_requests_closing_issues
      end
    end
  end
end

WorkItems::Widgets::Development.prepend_mod
