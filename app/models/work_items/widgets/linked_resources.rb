# frozen_string_literal: true

module WorkItems
  module Widgets
    class LinkedResources < Base
      delegate :zoom_meetings, to: :work_item
    end
  end
end
