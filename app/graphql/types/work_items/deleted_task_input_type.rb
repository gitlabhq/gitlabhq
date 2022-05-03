# frozen_string_literal: true

module Types
  module WorkItems
    class DeletedTaskInputType < BaseInputObject
      graphql_name 'WorkItemDeletedTaskInput'

      argument :id, ::Types::GlobalIDType[::WorkItem],
               required: true,
               description: 'Global ID of the task referenced in the work item\'s description.'
      argument :line_number_end, GraphQL::Types::Int,
               required: true,
               description: 'Last line in the Markdown source that defines the list item task.'
      argument :line_number_start, GraphQL::Types::Int,
               required: true,
               description: 'First line in the Markdown source that defines the list item task.'
    end
  end
end
