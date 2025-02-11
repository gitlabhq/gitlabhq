# frozen_string_literal: true

module Mutations
  module Todos
    # Base class for bulk todo operations

    class BaseMany < ::Mutations::BaseMutation # rubocop:disable GraphQL/GraphqlName -- Base class needs no name.
      MAX_UPDATE_AMOUNT = 100

      argument :ids,
        [::Types::GlobalIDType[::Todo]],
        required: true,
        description: 'Global IDs of the to-do items to process (a maximum of 100 is supported at once).'

      field :todos, [::Types::TodoType],
        null: false,
        description: 'Updated to-do items.'

      def resolve(ids:, **kwargs)
        check_update_limit!(amount: ids.size)

        todos = authorized_find_all_pending_by_current_user(model_ids_of(ids))
        updated_ids = process_todos(todos, **kwargs)

        {
          updated_ids: updated_ids,
          todos: Todo.id_in(updated_ids),
          errors: errors_on_objects(todos)
        }
      end

      private

      def process_todos(todos)
        raise NotImplementedError, "#{self.class} must implement #process_todos"
      end

      def todo_state_to_find
        raise NotImplementedError, "#{self.class} must implement #todo_state_to_find"
      end

      def model_ids_of(ids)
        ids.filter_map { |gid| gid.model_id.to_i }
      end

      def raise_too_many_todos_requested_error
        raise Gitlab::Graphql::Errors::ArgumentError, 'Too many to-do items requested.'
      end

      def check_update_limit!(amount:)
        raise_too_many_todos_requested_error if amount > MAX_UPDATE_AMOUNT
      end

      def errors_on_objects(todos)
        todos.flat_map { |todo| errors_on_object(todo) }
      end

      def authorized_find_all_pending_by_current_user(ids)
        return Todo.none if ids.blank? || current_user.nil?

        Todo.id_in(ids).for_user(current_user).with_state(todo_state_to_find)
      end
    end
  end
end
