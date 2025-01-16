# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes
      class CurrentUserTodosType < BaseObject
        graphql_name 'WorkItemWidgetCurrentUserTodos'
        description 'Represents a todos widget'

        implements ::Types::WorkItems::WidgetInterface
        implements ::Types::CurrentUserTodos

        private

        # Overriden as `Types::CurrentUserTodos` relies on `unpresented` being the Issuable record.
        def unpresented
          object.work_item
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
