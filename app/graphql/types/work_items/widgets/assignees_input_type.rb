# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class AssigneesInputType < BaseInputObject
        graphql_name 'WorkItemWidgetAssigneesInput'

        argument :assignee_ids, [::Types::GlobalIDType[::User]],
          required: true,
          description: 'Global IDs of assignees.',
          prepare: ->(ids, _) { ids.map(&:model_id) }
      end
    end
  end
end
