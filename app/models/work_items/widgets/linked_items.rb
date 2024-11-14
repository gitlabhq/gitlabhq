# frozen_string_literal: true

module WorkItems
  module Widgets
    class LinkedItems < Base
      delegate :linked_work_items, to: :work_item

      def self.quick_action_commands
        [:blocks, :blocked_by]
      end
    end
  end
end
