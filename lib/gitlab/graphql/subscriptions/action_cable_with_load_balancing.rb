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
          @serializer.wal_locations.blank? || !databases_in_sync?(@serializer.wal_locations)
        end
      end

      class WalInjectingSerializer
        include Gitlab::Database::LoadBalancing::WalTrackingSender

        DEFAULT_SERIALIZER = GraphQL::Subscriptions::Serialize

        attr_reader :wal_locations

        # rubocop: disable GitlabSecurity/PublicSend
        def load(str)
          value = Gitlab::Json.parse(str)

          @wal_locations = value['wal_locations']

          DEFAULT_SERIALIZER.send(:load_value, value['payload'])
        end

        def dump(obj)
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
