# frozen_string_literal: true

module Gitlab
  module Graphql
    module Subscriptions
      class ActionCableWithLoadBalancing < ::GraphQL::Subscriptions::ActionCableSubscriptions
        extend ::Gitlab::Utils::Override

        # When executing updates we are usually responding to a broadcast as a result of a DB update.
        # We use the primary so that we are sure that we are returning the newly updated data.
        override :execute_update
        def execute_update(subscription_id, event, object)
          ::Gitlab::Database::LoadBalancing::Session.current.use_primary!

          super
        end
      end
    end
  end
end
