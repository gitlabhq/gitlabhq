# frozen_string_literal: true

module Mutations
  module MergeRequests
    class SetSubscription < Base
      graphql_name 'MergeRequestSetSubscription'

      argument :subscribed_state,
               GraphQL::BOOLEAN_TYPE,
               required: true,
               description: 'The desired state of the subscription'

      def resolve(project_path:, iid:, subscribed_state:)
        merge_request = authorized_find!(project_path: project_path, iid: iid)
        project = merge_request.project

        merge_request.set_subscription(current_user, subscribed_state, project)

        {
          merge_request: merge_request,
          errors: merge_request.errors.full_messages
        }
      end
    end
  end
end
