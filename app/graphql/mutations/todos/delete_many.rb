# frozen_string_literal: true

module Mutations
  module Todos
    class DeleteMany < BaseMany
      graphql_name 'TodoDeleteMany'

      def resolve(ids:)
        verify_rate_limit!
        check_update_limit!(amount: ids.size)

        todos = authorized_find_all_pending_by_current_user(model_ids_of(ids))
        deleted_ids = process_todos(todos)

        {
          deleted_ids: deleted_ids,
          errors: errors_on_objects(todos)
        }
      end

      private

      def process_todos(todos)
        ::Todos::Delete::DoneTodosService.new.execute(todos)
      end

      def todo_state_to_find
        :done
      end

      def verify_rate_limit!
        return unless Gitlab::ApplicationRateLimiter.throttled?(:bulk_delete_todos, scope: [current_user])

        raise_resource_not_available_error!('This endpoint has been requested too many times. Try again later.')
      end
    end
  end
end
