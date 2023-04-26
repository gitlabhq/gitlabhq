# frozen_string_literal: true

module Gitlab
  module Graphql
    module Subscriptions
      class ActionCableWithLoadBalancing < ::GraphQL::Subscriptions::ActionCableSubscriptions
        extend ::Gitlab::Utils::Override
        include Gitlab::Database::LoadBalancing::WalTrackingReceiver

        def initialize(**options)
          super(serializer: WalInjectingSerializer.new, **options)
        end

        # We fall back to the primary in case no replica is sufficiently caught up.
        override :execute_update
        def execute_update(subscription_id, event, object)
          ::Gitlab::Database::LoadBalancing::Session.current.use_primary! if use_primary?

          super
        end

        private

        def use_primary?
          @serializer.wal_locations.blank? ||
            Feature.disabled?(:graphql_subs_lb) ||
            !databases_in_sync?(@serializer.wal_locations)
        end
      end

      class WalInjectingSerializer
        include Gitlab::Database::LoadBalancing::WalTrackingSender

        DEFAULT_SERIALIZER = GraphQL::Subscriptions::Serialize

        attr_reader :wal_locations

        # rubocop: disable GitlabSecurity/PublicSend
        def load(str)
          return DEFAULT_SERIALIZER.load(str) unless Feature.enabled?(:graphql_subs_lb)

          value = Gitlab::Json.parse(str)

          @wal_locations = value['wal_locations']

          DEFAULT_SERIALIZER.send(:load_value, value['payload'])
        end

        def dump(obj)
          return DEFAULT_SERIALIZER.dump(obj) unless Feature.enabled?(:graphql_subs_lb)

          Gitlab::Json.dump({
            'wal_locations' => wal_locations_by_db_name,
            'payload' => DEFAULT_SERIALIZER.send(:dump_value, obj)
          })
        end
        # rubocop: enable GitlabSecurity/PublicSend
      end
    end
  end
end
