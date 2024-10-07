# frozen_string_literal: true

module Gitlab
  module Graphql
    module Subscriptions
      class ActionCableWithLoadBalancing < ::GraphQL::Subscriptions::ActionCableSubscriptions
        extend ::Gitlab::Utils::Override
        include Gitlab::Database::LoadBalancing::WalTrackingSender
        include Gitlab::Database::LoadBalancing::WalTrackingReceiver

        KEY_PAYLOAD = 'gql_payload'
        KEY_WAL_LOCATIONS = 'wal_locations'

        override :execute_all
        def execute_all(event, object)
          super(event, {
            KEY_WAL_LOCATIONS => current_wal_locations,
            KEY_PAYLOAD => object
          })
        end

        # We fall back to the primary in case no replica is sufficiently caught up.
        override :execute_update
        def execute_update(subscription_id, event, object)
          # Make sure we do not accidentally try to unwrap messages that are not wrapped.
          # This could in theory happen if workers roll over where some send wrapped payload
          # and others expect the original payload.
          return super(subscription_id, event, object) unless wrapped_payload?(object)

          if use_primary?(object[KEY_WAL_LOCATIONS])
            ::Gitlab::Database::LoadBalancing::SessionMap
              .with_sessions(Gitlab::Database::LoadBalancing.base_models)
              .use_primary!
          end

          super(subscription_id, event, object[KEY_PAYLOAD])
        end

        private

        def wrapped_payload?(object)
          object.try(:key?, KEY_PAYLOAD)
        end

        def use_primary?(wal_locations)
          wal_locations.blank? || !databases_in_sync?(wal_locations)
        end

        # We stringify keys since otherwise the graphql-ruby serializer will inject additional metadata
        # to keep track of which keys used to be symbols.
        def current_wal_locations
          wal_locations_by_db_name&.stringify_keys
        end
      end
    end
  end
end
