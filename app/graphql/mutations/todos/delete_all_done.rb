# frozen_string_literal: true

module Mutations
  module Todos
    class DeleteAllDone < ::Mutations::BaseMutation
      graphql_name 'TodoDeleteAllDone'

      def resolve
        verify_rate_limit!

        delete_until = Time.now.utc.to_datetime.to_s

        ::Todos::DeleteAllDoneWorker.perform_async(current_user.id, delete_until) # rubocop:disable CodeReuse/Worker -- we need to do this asynchronously

        {
          message: format(_('Your request has succeeded. Results will be visible in a couple of minutes.')),
          errors: []
        }
      end

      private

      def verify_rate_limit!
        return unless Gitlab::ApplicationRateLimiter.throttled?(:delete_all_todos, scope: [current_user])

        raise_resource_not_available_error!('This endpoint has been requested too many times. Try again later.')
      end
    end
  end
end
