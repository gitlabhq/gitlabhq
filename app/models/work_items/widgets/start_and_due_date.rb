# frozen_string_literal: true

module WorkItems
  module Widgets
    class StartAndDueDate < Base
      include ::Gitlab::Utils::StrongMemoize

      class << self
        def quick_action_commands
          %i[due remove_due_date]
        end

        def quick_action_params
          %i[due_date]
        end
      end

      # rubocop:disable Gitlab/NoCodeCoverageComment -- overridden and tested in EE
      # :nocov:
      def fixed?
        true
      end

      def can_rollup?
        false
      end
      # :nocov:
      # rubocop:enable Gitlab/NoCodeCoverageComment

      def start_date
        dates_source.start_date_fixed
      end

      def due_date
        dates_source.due_date_fixed
      end

      private

      def dates_source
        return DatesSource.new if work_item.blank?
        return work_item.dates_source if work_item.dates_source.present?

        work_item.build_dates_source(
          start_date_is_fixed: true,
          due_date_is_fixed: true,
          start_date_fixed: work_item.start_date,
          due_date_fixed: work_item.due_date
        )
      end
      strong_memoize_attr :dates_source
    end
  end
end

WorkItems::Widgets::StartAndDueDate.prepend_mod
