# frozen_string_literal: true

module Subscriptions
  class BaseSubscription < GraphQL::Schema::Subscription
    object_class Types::BaseObject
    field_class Types::BaseField

    UNAUTHORIZED_ERROR_MESSAGE = 'Unauthorized subscription'

    def initialize(object:, context:, field:)
      super

      # Reset user so that we don't use a stale user for authorization
      current_user.reset if current_user
    end

    # We override graphql-ruby's default `subscribe` since it returns
    # :no_response instead, which leads to empty hashes rendered out
    # to the caller which has caused problems in the client.
    #
    # Eventually, we should move to an approach where the caller receives
    # a response here upon subscribing, but we don't need this currently
    # because Vue components also perform an initial fetch query.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/402614
    def subscribe(*)
      nil
    end

    def authorized?(*)
      raise NotImplementedError
    end

    private

    def unauthorized!
      unsubscribe if context.query.subscription_update?

      raise GraphQL::ExecutionError, UNAUTHORIZED_ERROR_MESSAGE
    end

    def current_user
      context[:current_user]
    end
  end
end
