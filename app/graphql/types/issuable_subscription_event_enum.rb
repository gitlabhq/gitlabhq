# frozen_string_literal: true

module Types
  class IssuableSubscriptionEventEnum < BaseEnum
    graphql_name 'IssuableSubscriptionEvent'
    description 'Values for subscribing and unsubscribing from issuables'

    value 'SUBSCRIBE', 'Subscribe to an issuable.', value: 'subscribe'
    value 'UNSUBSCRIBE', 'Unsubscribe from an issuable.', value: 'unsubscribe'
  end
end
