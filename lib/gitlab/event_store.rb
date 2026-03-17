# frozen_string_literal: true

# Gitlab::EventStore is a simple pub-sub mechanism that lets you publish
# domain events and use Sidekiq workers as event handlers.
#
# It can be used to decouple domains from different bounded contexts
# by publishing domain events and let any interested parties subscribe
# to them.
#
module Gitlab
  module EventStore
    Error = Class.new(StandardError)
    InvalidEvent = Class.new(Error)
    InvalidSubscriber = Class.new(Error)
    SUBSCRIPTION_GROUPS = [
      Subscriptions::MergeRequestsSubscriptions,
      Subscriptions::CiSubscriptions,
      Subscriptions::NamespacesSubscriptions,
      Subscriptions::MlSubscriptions,
      Subscriptions::PagesSubscriptions,
      Subscriptions::WorkItemsSubscriptions
    ].freeze

    class << self
      def publish(event)
        instance.publish(event)
      end

      def publish_group(events)
        instance.publish_group(events)
      end

      def instance
        @instance ||= Store.new { |store| configure!(store) }
      end

      private

      # Define all event subscriptions using a domain-specific subscription group
      def configure!(store)
        register_subscriptions(store)
      end

      def register_subscriptions(store)
        subscription_groups.each { |subscription_group| subscription_group.new(store).register }
      end

      # overridden in EE
      def subscription_groups
        SUBSCRIPTION_GROUPS
      end
    end
  end
end

Gitlab::EventStore.prepend_mod_with('Gitlab::EventStore')
