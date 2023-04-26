# frozen_string_literal: true

module Gitlab
  module Metrics
    module Subscribers
      class ActionCable < ActiveSupport::Subscriber
        include Gitlab::Utils::StrongMemoize

        SOURCE_DIRECT = 'channel'
        SOURCE_GRAPHQL_EVENT = 'graphql-event'
        SOURCE_GRAPHQL_SUBSCRIPTION = 'graphql-subscription'
        SOURCE_OTHER = 'unknown'

        attach_to :action_cable

        SINGLE_CLIENT_TRANSMISSION = :action_cable_single_client_transmissions_total
        TRANSMIT_SUBSCRIPTION_CONFIRMATION = :action_cable_subscription_confirmations_total
        TRANSMIT_SUBSCRIPTION_REJECTION = :action_cable_subscription_rejections_total
        BROADCAST = :action_cable_broadcasts_total
        DATA_TRANSMITTED_BYTES = :action_cable_transmitted_bytes_total

        def transmit_subscription_confirmation(event)
          confirm_subscription_counter.increment
        end

        def transmit_subscription_rejection(event)
          reject_subscription_counter.increment
        end

        def transmit(event)
          payload = event.payload

          labels = {
            channel: payload[:channel_class],
            caller: normalize_source(payload[:via])
          }
          labels[:broadcasting] = graphql_event_broadcasting_from(payload[:data])

          transmit_counter.increment(labels)
          data_size = Gitlab::Json.generate(payload[:data]).bytesize
          transmitted_bytes_counter.increment(labels, data_size)
        end

        def broadcast(event)
          broadcast_counter.increment({ broadcasting: normalize_source(event.payload[:broadcasting]) })
        end

        private

        # Since transmission sources can have high dimensionality when they carry IDs, we need to
        # collapse them. If it's not a well-know broadcast, we report it as "other".
        def normalize_source(source)
          return SOURCE_DIRECT if source.blank?

          normalized_source = source.gsub('streamed from ', '')

          if normalized_source.start_with?(SOURCE_GRAPHQL_EVENT)
            # Take at most two levels of topic namespacing.
            normalized_source.split(':').reject(&:empty?).take(2).join(':') # rubocop: disable CodeReuse/ActiveRecord
          elsif normalized_source.start_with?(SOURCE_GRAPHQL_SUBSCRIPTION)
            SOURCE_GRAPHQL_SUBSCRIPTION
          else
            SOURCE_OTHER
          end
        end

        # When possible tries to query operation name. This will only return data
        # for GraphQL subscription broadcasts.
        def graphql_event_broadcasting_from(payload_data)
          # Depending on whether the query result was passed in-process from a direct
          # execution (e.g. in response to a subcription request) or cross-process by
          # going through PubSub, we might encounter either string or symbol keys.
          # We do not use deep_transform_keys here because the payload can be large
          # and performance would be affected.
          query_result = payload_data[:result] || payload_data['result'] || {}
          query_result_data = query_result['data'] || {}
          gql_operation = query_result_data.each_key.first

          return unless gql_operation

          "#{SOURCE_GRAPHQL_EVENT}:#{gql_operation}"
        end

        def transmit_counter
          strong_memoize("transmission_counter") do
            ::Gitlab::Metrics.counter(
              SINGLE_CLIENT_TRANSMISSION,
              'The number of ActionCable messages transmitted to any client in any channel'
            )
          end
        end

        def broadcast_counter
          strong_memoize("broadcast_counter") do
            ::Gitlab::Metrics.counter(
              BROADCAST,
              'The number of ActionCable broadcasts emitted'
            )
          end
        end

        def confirm_subscription_counter
          strong_memoize("confirm_subscription_counter") do
            ::Gitlab::Metrics.counter(
              TRANSMIT_SUBSCRIPTION_CONFIRMATION,
              'The number of ActionCable subscriptions from clients confirmed'
            )
          end
        end

        def reject_subscription_counter
          strong_memoize("reject_subscription_counter") do
            ::Gitlab::Metrics.counter(
              TRANSMIT_SUBSCRIPTION_REJECTION,
              'The number of ActionCable subscriptions from clients rejected'
            )
          end
        end

        def transmitted_bytes_counter
          strong_memoize("transmitted_bytes_counter") do
            ::Gitlab::Metrics.counter(
              DATA_TRANSMITTED_BYTES,
              'Total number of bytes transmitted over ActionCable'
            )
          end
        end
      end
    end
  end
end
