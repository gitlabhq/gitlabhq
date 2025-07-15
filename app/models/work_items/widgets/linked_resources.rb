# frozen_string_literal: true

module WorkItems
  module Widgets
    class LinkedResources < Base
      def zoom_meetings
        work_item.zoom_meetings.added_to_issue
      end
    end
  end
end
