# frozen_string_literal: true

module Types
  module Issuables
    class SubscriptionStatusEnum < BaseEnum
      graphql_name 'SubscriptionStatus'
      description 'Status of the subscription to an issuable.'

      value 'EXPLICITLY_SUBSCRIBED', 'User is explicitly subscribed to the issuable.',
        value: :explicitly_subscribed

      value 'EXPLICITLY_UNSUBSCRIBED', 'User is explicitly unsubscribed from the issuable.',
        value: :explicitly_unsubscribed
    end
  end
end
