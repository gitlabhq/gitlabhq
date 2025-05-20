# frozen_string_literal: true

module Issues
  module SortArguments
    extend ActiveSupport::Concern
    include ::WorkItems::NonStableCursorSortOptions

    included do
      argument :sort, Types::IssueSortEnum,
        description: 'Sort issues by the criteria.',
        required: false,
        default_value: :created_desc
    end
  end
end
