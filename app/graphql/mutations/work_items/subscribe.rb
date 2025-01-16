# frozen_string_literal: true

module Mutations
  module WorkItems
    class Subscribe < BaseMutation
      graphql_name 'WorkItemSubscribe'

      argument :id, ::Types::GlobalIDType[::WorkItem],
        required: true,
        description: 'Global ID of the work item.'

      argument :subscribed,
        GraphQL::Types::Boolean,
        required: true,
        description: 'Desired state of the subscription.'

      field :work_item, ::Types::WorkItemType,
        null: true,
        description: 'Work item after mutation.'

      authorize :update_subscription

      def resolve(args)
        work_item = authorized_find!(id: args[:id])

        update_subscription(work_item, args[:subscribed])

        {
          work_item: work_item,
          errors: []
        }
      end

      private

      def update_subscription(work_item, subscribed_state)
        work_item.set_subscription(current_user, subscribed_state, work_item.project)
      end
    end
  end
end
