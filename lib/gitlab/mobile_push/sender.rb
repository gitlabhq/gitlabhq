# frozen_string_literal: true

module Gitlab
  module MobilePush
    # Sends one payload per phone through a shared ApnsClient, drops dead
    # tokens and counts every result. One instance per job; callers close it.
    class Sender
      # ApnsClient result -> `result` label on the counter.
      RESULT_LABELS = {
        delivered: 'delivered',
        bad_token: 'evicted',
        failed: 'failed',
        skipped: 'skipped_not_configured'
      }.freeze

      # Yields each subscription for its payload and returns the ApnsClient
      # result per subscription.
      def deliver(subscriptions)
        subscriptions.map do |subscription|
          result = client.push(subscription, yield(subscription))
          subscription.destroy if result == :bad_token
          counter.increment(result: RESULT_LABELS.fetch(result, 'failed'))
          result
        end
      end

      def close
        @client&.close
      end

      private

      # Built on the first send only, so a job that sends nothing opens no connection.
      def client
        @client ||= ApnsClient.new
      end

      def counter
        @counter ||= Gitlab::Metrics.counter(
          :mobile_push_notifications_total,
          'Count of mobile push notification processing outcomes'
        )
      end
    end
  end
end
