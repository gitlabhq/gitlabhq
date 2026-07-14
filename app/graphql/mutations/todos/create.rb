# frozen_string_literal: true

module Mutations
  module Todos
    class Create < ::Mutations::BaseMutation
      graphql_name 'TodoCreate'

      authorize :create_todo
      authorize_granular_token permissions: :create_todo,
        boundaries: [
          { boundary_argument: :target_id, boundary: :resource_parent, boundary_type: :project },
          { boundary_argument: :target_id, boundary: :resource_parent, boundary_type: :group }
        ]

      argument :target_id,
        Types::GlobalIDType[Todoable],
        required: true,
        description: "Global ID of the to-do item's parent. Issues, " \
          "merge requests, designs, and epics are supported."

      field :todo, Types::TodoType,
        null: true,
        description: 'To-do item created.'

      def resolve(target_id:)
        target = authorized_find!(id: target_id)

        todo = TodoService.new.mark_todo(target, current_user)&.first
        errors = errors_on_object(todo) if todo

        {
          todo: todo,
          errors: errors
        }
      end
    end
  end
end
