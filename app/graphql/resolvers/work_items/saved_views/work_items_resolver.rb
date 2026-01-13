# frozen_string_literal: true

module Resolvers
  module WorkItems
    module SavedViews
      class WorkItemsResolver < BaseResolver
        include ::WorkItems::LookAheadPreloads

        type Types::WorkItemType.connection_type, null: true

        def resolve(**pagination_args); end
      end
    end
  end
end
