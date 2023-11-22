# frozen_string_literal: true

module WorkItems
  module Widgets
    class Assignees < Base
      delegate :assignees, to: :work_item
      delegate :allows_multiple_assignees?, to: :work_item

      def self.quick_action_commands
        [:assign, :unassign, :reassign]
      end

      def self.quick_action_params
        [:assignee_ids]
      end

      def self.can_invite_members?(user, resource_parent)
        user.can?("admin_#{resource_parent.to_ability_name}_member".to_sym, resource_parent)
      end
    end
  end
end

WorkItems::Widgets::Assignees.prepend_mod
