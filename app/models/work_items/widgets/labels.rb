# frozen_string_literal: true

module WorkItems
  module Widgets
    class Labels < Base
      delegate :labels, to: :work_item
      delegate :allows_scoped_labels?, to: :work_item

      def self.quick_action_commands
        [:label, :labels, :relabel, :remove_label, :unlabel]
      end

      def self.quick_action_params
        [:add_label_ids, :remove_label_ids, :label_ids]
      end
    end
  end
end
