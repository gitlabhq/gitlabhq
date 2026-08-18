# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class DescriptionInputType < BaseInputObject
        graphql_name 'WorkItemWidgetDescriptionInput'

        argument :description, GraphQL::Types::String,
          required: false,
          description: copy_field_description(Types::WorkItemType, :description)

        argument :task_list_toggle, ::Types::WorkItems::TaskListToggleInputType,
          required: false,
          experiment: { milestone: '19.2' },
          description: 'Toggle a single task list item instead of replacing the full description. ' \
            'Only supported when updating a work item, and only when the ' \
            '`work_items_task_list_toggle` feature flag is enabled.'

        validates exactly_one_of: %i[description task_list_toggle]
      end
    end
  end
end
