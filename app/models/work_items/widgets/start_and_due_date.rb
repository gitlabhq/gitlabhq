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

        def sorting_keys
          {
            start_date_asc: {
              description: 'Start date by ascending order.',
              experiment: { milestone: '17.9' }
            },
            start_date_desc: {
              description: 'Start date by descending order.',
              experiment: { milestone: '17.9' }
            },
            due_date_asc: {
              description: 'Due date by ascending order.',
              experiment: { milestone: '17.9' }
            },
            due_date_desc: {
              description: 'Due date by descending order.',
              experiment: { milestone: '17.9' }
            }
          }
        end
      end

      # rubocop:disable Gitlab/NoCodeCoverageComment -- overridden and tested in EE
      # :nocov:
      def fixed?
        rollupable_dates.fixed?
      end

      def can_rollup?
        false
      end
      # :nocov:
      # rubocop:enable Gitlab/NoCodeCoverageComment

      def start_date
        return work_item&.start_date unless dates_source_present?

        rollupable_dates.start_date
      end

      def due_date
        return work_item&.due_date unless dates_source_present?

        rollupable_dates.due_date
      end

      private

      def rollupable_dates
        WorkItems::RollupableDates.new(
          work_item.dates_source || work_item.build_dates_source,
          can_rollup: can_rollup?
        )
      end
      strong_memoize_attr :rollupable_dates

      def dates_source_present?
        return false if work_item&.dates_source.blank?

        work_item
          .dates_source
          .slice(:start_date, :start_date_fixed, :due_date, :due_date_fixed)
          .any? { |_, value| value.present? }
      end
      strong_memoize_attr :dates_source_present?
    end
  end
end

WorkItems::Widgets::StartAndDueDate.prepend_mod
