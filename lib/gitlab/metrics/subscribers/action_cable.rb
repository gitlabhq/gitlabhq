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

        def transmit_subscription_confirmation(event)
          confirm_subscription_counter.increment
        end

        def transmit_subscription_rejection(event)
          reject_subscription_counter.increment
        end

        def transmit(event)
          transmit_counter.increment
        end

        def broadcast(event)
          broadcast_counter.increment
        end

        private

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
      end
    end
  end
end
