# frozen_string_literal: true

module WorkItems
  module Widgets
    class LinkedItems < Base
      delegate :linked_work_items, to: :work_item

      def self.quick_action_commands
        %i[blocks blocked_by relate]
      end
    end
  end
end
