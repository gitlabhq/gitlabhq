# frozen_string_literal: true

module Types
  module WorkItems
    class ConvertTaskInputType < BaseInputObject
      graphql_name 'WorkItemConvertTaskInput'

      argument :line_number_end, GraphQL::Types::Int,
        required: true,
        description: 'Last line in the Markdown source that defines the list item task.'
      argument :line_number_start, GraphQL::Types::Int,
        required: true,
        description: 'First line in the Markdown source that defines the list item task.'
      argument :lock_version, GraphQL::Types::Int,
        required: true,
        description: 'Current lock version of the work item containing the task in the description.'
      argument :title, GraphQL::Types::String,
        required: true,
        description: 'Full string of the task to be replaced. New title for the created work item.'
      argument :work_item_type_id, ::Types::GlobalIDType[::WorkItems::Type],
        required: true,
        description: 'Global ID of the work item type used to create the new work item.',
        prepare: ->(attribute, _ctx) { work_item_type_global_id(attribute) }

      class << self
        def work_item_type_global_id(global_id)
          global_id&.model_id
        end
      end
    end
  end
end
