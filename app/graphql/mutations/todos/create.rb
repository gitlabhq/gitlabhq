# frozen_string_literal: true

module Mutations
  module Todos
    class Create < ::Mutations::Todos::Base
      graphql_name 'TodoCreate'

      authorize :create_todo

      argument :target_id,
               Types::GlobalIDType[Todoable],
               required: true,
               description: "Global ID of the to-do item's parent. Issues, merge requests, designs, and epics are supported."

      field :todo, Types::TodoType,
            null: true,
            description: 'To-do item created.'

      def resolve(target_id:)
        id = ::Types::GlobalIDType[Todoable].coerce_isolated_input(target_id)
        target = authorized_find!(id)

        todo = TodoService.new.mark_todo(target, current_user)&.first
        errors = errors_on_object(todo) if todo

        {
          todo: todo,
          errors: errors
        }
      end

      private

      def find_object(id)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
