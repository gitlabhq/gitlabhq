# frozen_string_literal: true

module Gitlab
  module Metrics
    module Subscribers
      class ActionCable < ActiveSupport::Subscriber
        include Gitlab::Utils::StrongMemoize

        attach_to :action_cable

        SINGLE_CLIENT_TRANSMISSION = :action_cable_single_client_transmissions_total
        TRANSMIT_SUBSCRIPTION_CONFIRMATION = :action_cable_subscription_confirmations_total
        TRANSMIT_SUBSCRIPTION_REJECTION = :action_cable_subscription_rejections_total
        BROADCAST = :action_cable_broadcasts_total
        DATA_TRANSMITTED_BYTES = :action_cable_transmitted_bytes

        def transmit_subscription_confirmation(event)
          confirm_subscription_counter.increment
        end

        def transmit_subscription_rejection(event)
          reject_subscription_counter.increment
        end

        def transmit(event)
          transmit_counter.increment

          if event.payload.present?
            channel = event.payload[:channel_class]
            operation = operation_name_from(event.payload)
            data_size = ::ActiveSupport::JSON.encode(event.payload[:data]).bytesize

            transmitted_bytes_histogram.observe({ channel: channel, operation: operation }, data_size)
          end
        end

        def broadcast(event)
          broadcast_counter.increment
        end

        private

        # When possible tries to query operation name
        def operation_name_from(payload)
          data = payload.dig(:data, 'result', 'data') || {}

          data.each_key.first
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

        def transmitted_bytes_histogram
          strong_memoize("transmitted_bytes_histogram") do
            ::Gitlab::Metrics.histogram(DATA_TRANSMITTED_BYTES, 'Message size, in bytes, transmitted over action cable')
          end
        end
      end
    end
  end
end
