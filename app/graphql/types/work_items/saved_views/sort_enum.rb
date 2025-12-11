# frozen_string_literal: true

module Types
  module WorkItems
    module SavedViews
      class SortEnum < ::Types::SortEnum
        graphql_name 'WorkItemsSavedViewsSort'
        description 'Values for sorting saved views'

        value 'RELATIVE_POSITION', description: 'Relative position by ascending order. If user is ' \
                                     'logged out, or explicitly subscribed is not passed, falls back to id sort.',
          value: :relative_position

        value 'ID', description: 'Ordered by id.', value: :id
      end
    end
  end
end
