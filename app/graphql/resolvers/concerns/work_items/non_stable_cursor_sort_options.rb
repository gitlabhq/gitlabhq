# frozen_string_literal: true

module WorkItems
  module NonStableCursorSortOptions
    extend ActiveSupport::Concern

    NON_STABLE_CURSOR_SORTS = %i[priority_asc priority_desc
      popularity_asc popularity_desc
      label_priority_asc label_priority_desc
      milestone_due_asc milestone_due_desc
      escalation_status_asc escalation_status_desc].freeze

    private

    def non_stable_cursor_sort?(sort)
      NON_STABLE_CURSOR_SORTS.include?(sort)
    end
  end
end
