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
        KEY_CORRELATION_ID = 'correlation_id'

        override :execute_all
        def execute_all(event, object)
          super(event, {
            KEY_WAL_LOCATIONS => current_wal_locations,
            KEY_CORRELATION_ID => ::Labkit::Correlation::CorrelationId.current_id,
            KEY_PAYLOAD => object
          })
        end

        # The payload carries global IDs, so `super` is what turns them back into records.
        # The fallback to the primary has to be decided here, before that lookup, or it can
        # miss a row the replica has not received yet.
        override :load_action_cable_message
        def load_action_cable_message(message, context)
          apply_primary_fallback(envelope_in(message)) if pin_before_payload_load?

          super
        end

        override :execute_update
        def execute_update(subscription_id, event, object)
          # Make sure we do not accidentally try to unwrap messages that are not wrapped.
          # This could in theory happen if workers roll over where some send wrapped payload
          # and others expect the original payload.
          return super(subscription_id, event, object) unless wrapped_payload?(object)

          use_primary! if !pin_before_payload_load? && use_primary?(object[KEY_WAL_LOCATIONS])

          super(subscription_id, event, object[KEY_PAYLOAD])
        end

        private

        # Actor is the current request rather than the instance so the rollout can be
        # done by percentage of actors. One ActionCable work unit is one request here.
        def pin_before_payload_load?
          Feature.enabled?(:graphql_subscription_primary_fallback_on_load, Feature.current_request)
        end

        def use_primary!
          ::Gitlab::Database::LoadBalancing::SessionMap
            .with_sessions(Gitlab::Database::LoadBalancing.base_models)
            .use_primary!
        end

        def wrapped_payload?(object)
          object.try(:key?, KEY_PAYLOAD)
        end

        def apply_primary_fallback(envelope)
          return unless envelope

          locations = envelope[KEY_WAL_LOCATIONS] || {}
          return unless use_primary?(locations)

          use_primary!

          ::Gitlab::Database::LoadBalancing::Logger.info(
            event: :graphql_subscription_primary_fallback,
            fallback_reason: fallback_reason(envelope, locations),
            ::Labkit::Fields::CORRELATION_ID => envelope[KEY_CORRELATION_ID]
          )
        end

        def fallback_reason(envelope, locations)
          return :envelope_unreadable unless wrapped_payload?(envelope)
          return :wal_locations_absent if locations.blank?

          :replicas_behind
        end

        # Reads the envelope off the raw broadcast without resolving any global ID, so the
        # routing decision itself stays off the database. Returns nil for a payload that is
        # not ours to route, and {} when it is ours but cannot be read, which pins.
        def envelope_in(message)
          envelope = ::Gitlab::Json::SafeParser.parse(message)
          return unless wrapped_payload?(envelope)

          envelope
        rescue ::JSON::ParserError
          {}
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
