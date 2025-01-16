# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes
      class DescriptionType < BaseObject
        graphql_name 'WorkItemWidgetDescription'
        description 'Represents a description widget'

        implements ::Types::WorkItems::WidgetInterface

        field :description, GraphQL::Types::String,
          null: true,
          description: 'Description of the work item.'
        field :edited, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the description has been edited since the work item was created.',
          method: :edited?
        field :last_edited_at, ::Types::TimeType,
          null: true,
          description: 'Timestamp of when the work item\'s description was last edited.'
        field :last_edited_by, ::Types::UserType,
          null: true,
          description: 'User that made the last edit to the work item\'s description.'
        field :task_completion_status, ::Types::TaskCompletionStatus, null: false,
          description: 'Task completion status of the work item.'

        markdown_field :description_html, null: true, &:work_item
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
