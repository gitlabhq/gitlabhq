# frozen_string_literal: true

module WorkItems
  module Widgets
    class LinkedItems < Base
      delegate :linked_work_items, to: :work_item

      def self.quick_action_commands
        %i[relate unlink]
      end
    end
  end
end

::WorkItems::Widgets::LinkedItems.prepend_mod
