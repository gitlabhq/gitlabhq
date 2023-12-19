# frozen_string_literal: true

module ActivityPub
  module Projects
    class ReleasesFollowService < ReleasesSubscriptionService
      def execute
        unless subscriber_url
          errors << "You need to provide an actor id for your subscriber"
          return false
        end

        return true if previous_subscription.present?

        subscription = ReleasesSubscription.new(
          subscriber_url: subscriber_url,
          subscriber_inbox_url: subscriber_inbox_url,
          payload: payload,
          project: project
        )

        unless subscription.save
          errors.concat(subscription.errors.full_messages)
          return false
        end

        enqueue_subscription(subscription)
        true
      end

      private

      def subscriber_inbox_url
        return unless payload['actor'].is_a?(Hash)

        payload['actor']['inbox']
      end

      def enqueue_subscription(subscription)
        ReleasesSubscriptionWorker.perform_async(subscription.id)
      end
    end
  end
end
