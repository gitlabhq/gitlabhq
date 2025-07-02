# frozen_string_literal: true

module Types
  module WorkItems
    class SubscriptionEventEnum < BaseEnum
      graphql_name 'WorkItemSubscriptionEvent'
      description 'Values for work item subscription events'

      value 'SUBSCRIBE', 'Subscribe to a work item.', value: 'subscribe'
      value 'UNSUBSCRIBE', 'Unsubscribe from a work item.', value: 'unsubscribe'
    end
  end
end
