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
              description: 'start date by ascending order.',
              experiment: { milestone: '17.9' }
            },
            start_date_desc: {
              description: 'start date by descending order.',
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
        true
      end

      def can_rollup?
        false
      end
      # :nocov:
      # rubocop:enable Gitlab/NoCodeCoverageComment

      def start_date
        return work_item&.start_date unless dates_source_present?

        dates_source.start_date_fixed
      end

      def due_date
        return work_item&.due_date unless dates_source_present?

        dates_source.due_date_fixed
      end

      private

      def dates_source
        return DatesSource.new if work_item.blank?

        work_item.dates_source || work_item.build_dates_source
      end
      strong_memoize_attr :dates_source

      def dates_source_present?
        return false if work_item&.dates_source.blank?

        work_item
          .dates_source
          .slice(:start_date, :start_date_fixed, :due_date, :due_date_fixed)
          .any? { |_, value| value.present? }
      end
    end
  end
end

WorkItems::Widgets::StartAndDueDate.prepend_mod
