# frozen_string_literal: true

module Types
  module WorkItems
    class TaskListToggleInputType < BaseInputObject
      graphql_name 'TaskListToggleInput'
      description 'Toggles a single task list item checkbox instead of replacing the full Markdown source.'

      argument :checked, GraphQL::Types::Boolean,
        required: true,
        description: 'Indicates the state the task list item should be toggled to.'

      argument :line_source, GraphQL::Types::String,
        required: true,
        description: 'Full Markdown source of the line containing the task list item; ' \
          'used to detect concurrent edits.'

      argument :line_sourcepos, GraphQL::Types::String,
        required: true,
        description: 'Source position of the task list item in the Markdown source; for example, `5:1-5:14`.'
    end
  end
end
