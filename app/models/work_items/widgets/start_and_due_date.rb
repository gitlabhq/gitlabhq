# frozen_string_literal: true

module WorkItems
  module Widgets
    class StartAndDueDate < Base
      include ::Gitlab::Utils::StrongMemoize

      def self.quick_action_commands
        [:due, :remove_due_date]
      end

      def self.quick_action_params
        [:due_date]
      end

      def start_date
        return dates_source.start_date_fixed if dates_source.present?

        work_item&.start_date
      end

      def due_date
        return dates_source.due_date_fixed if dates_source.present?

        work_item&.due_date
      end

      private

      def dates_source
        work_item&.dates_source
      end
      strong_memoize_attr :dates_source
    end
  end
end
