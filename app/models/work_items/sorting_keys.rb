# frozen_string_literal: true

module WorkItems
  class SortingKeys
    DEFAULT_SORTING_KEYS = {
      closed_at_asc: {
        description: 'Closed time by ascending order.',
        experiment: { milestone: '17.10' }
      },
      closed_at_desc: {
        description: 'Closed time by descending order.',
        experiment: { milestone: '17.10' }
      },
      escalation_status_asc: {
        description: 'Status from triggered to resolved.',
        experiment: { milestone: '17.10' }
      },
      escalation_status_desc: {
        description: 'Status from resolved to triggered.',
        experiment: { milestone: '17.10' }
      },
      popularity_asc: {
        description: 'Number of upvotes (awarded "thumbs up" emoji) by ascending order.',
        experiment: { milestone: '17.10' }
      },
      popularity_desc: {
        description: 'Number of upvotes (awarded "thumbs up" emoji) by descending order.',
        experiment: { milestone: '17.10' }
      },
      priority_asc: {
        description: 'Priority by ascending order.',
        experiment: { milestone: '17.10' }
      },
      priority_desc: {
        description: 'Priority by descending order.',
        experiment: { milestone: '17.10' }
      },
      relative_position_asc: {
        description: 'Relative position by ascending order.',
        experiment: { milestone: '17.10' }
      },
      severity_asc: {
        description: 'Severity from less critical to more critical.',
        experiment: { milestone: '17.10' }
      },
      severity_desc: {
        description: 'Severity from more critical to less critical.',
        experiment: { milestone: '17.10' }
      },
      updated_desc: {
        description: 'Updated at descending order.'
      },
      updated_asc: {
        description: 'Updated at ascending order.'
      },
      created_desc: {
        description: 'Created at descending order.'
      },
      created_asc: {
        description: 'Created at ascending order.'
      },
      title_asc: {
        description: 'Title by ascending order.'
      },
      title_desc: {
        description: 'Title by descending order.'
      }
    }.freeze

    class << self
      include ::Gitlab::Utils::StrongMemoize

      def all
        DEFAULT_SORTING_KEYS.merge(widgets_sorting_keys)
      end

      def widgets_sorting_keys
        ::WorkItems::WidgetDefinition.widget_classes
          .map(&:sorting_keys)
          .reduce({}, :merge)
      end
      strong_memoize_attr :widgets_sorting_keys
    end
  end
end
