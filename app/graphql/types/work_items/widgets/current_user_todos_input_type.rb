# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class CurrentUserTodosInputType < BaseInputObject
        graphql_name 'WorkItemWidgetCurrentUserTodosInput'

        argument :action, ::Types::WorkItems::TodoUpdateActionEnum,
          required: true,
          description: 'Action for the update.'

        argument :todo_id,
          ::Types::GlobalIDType[::Todo],
          required: false,
          description: "Global ID of the to-do. If not present, all to-dos of the work item will be updated.",
          prepare: ->(id, _) { id.model_id }
      end
    end
  end
end
