# frozen_string_literal: true

module WorkItems
  module Widgets
    class Hierarchy < Base
      include Gitlab::Utils::StrongMemoize

      def parent
        work_item.work_item_parent
      end

      def children
        work_item.work_item_children_by_relative_position
      end

      def ancestors
        work_item.ancestors
      end

      def has_parent?
        parent.present?
      end

      def rolled_up_counts_by_type
        work_item.work_item_type.descendant_types.map do |descendant_type|
          { work_item_type: descendant_type, counts_by_state: counts_by_state(descendant_type) }
        end
      end

      def depth_limit_reached_by_type
        work_item.work_item_type.descendant_types.map do |child_type|
          { work_item_type: child_type, depth_limit_reached: work_item.max_depth_reached?(child_type) }
        end
      end

      def self.quick_action_commands
        [:set_parent, :add_child, :remove_parent, :remove_child]
      end

      def self.quick_action_params
        [:set_parent, :add_child, :remove_parent, :remove_child]
      end

      def self.process_quick_action_param(param_name, value)
        return super unless param_name.in?(quick_action_params) && value.present?

        if [:set_parent, :remove_parent].include?(param_name)
          { parent: value.is_a?(WorkItem) ? value : nil }
        elsif param_name == :remove_child
          { remove_child: value }
        else
          { children: value }
        end
      end

      private

      def counts_by_state(work_item_type)
        open_count = counts_by_type_and_state.fetch(
          [work_item_type.attributes['correct_id'], WorkItem.available_states[:opened]],
          0
        )
        closed_count = counts_by_type_and_state.fetch(
          [work_item_type.attributes['correct_id'], WorkItem.available_states[:closed]],
          0
        )

        {
          all: open_count + closed_count,
          opened: open_count,
          closed: closed_count
        }
      end

      def counts_by_type_and_state
        work_item.descendants
          .group(:"#{::Gitlab::Issues::TypeAssociationGetter.call}_id", :state_id)
          .count
      end
      strong_memoize_attr :counts_by_type_and_state
    end
  end
end
