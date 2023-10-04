# frozen_string_literal: true

module WorkItems
  module Widgets
    class Hierarchy < Base
      def parent
        work_item.work_item_parent
      end

      def children
        work_item.work_item_children_by_relative_position
      end

      def self.quick_action_commands
        [:set_parent]
      end

      def self.quick_action_params
        [:set_parent]
      end

      def self.process_quick_action_param(param_name, value)
        return super unless param_name == :set_parent && value

        { parent: value }
      end
    end
  end
end
