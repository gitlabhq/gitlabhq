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

      def ancestors
        work_item.ancestors
      end

      def self.quick_action_commands
        [:set_parent, :add_child, :remove_parent]
      end

      def self.quick_action_params
        [:set_parent, :add_child, :remove_parent]
      end

      def self.sync_params
        [:parent]
      end

      def self.process_quick_action_param(param_name, value)
        return super unless param_name.in?(quick_action_params) && value.present?

        if [:set_parent, :remove_parent].include?(param_name)
          { parent: value.is_a?(WorkItem) ? value : nil }
        else
          { children: value }
        end
      end

      def self.process_sync_params(params)
        parent_param = params.fetch(:parent, nil)

        if parent_param&.work_item
          { parent: parent_param.work_item }
        else
          {}
        end
      end
    end
  end
end
