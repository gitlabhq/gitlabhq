# frozen_string_literal: true

module Notifications
  module MobilePush
    # Delivers APNs push notifications for a batch of freshly created todos
    # (one Todos::PushNotificationWorker job per TodoService#create_todos
    # call). Loads the batch with users and subscriptions preloaded, enforces
    # the per-recipient :mobile_push_notifications flag and rate limit, and
    # returns per-outcome tallies in the ServiceResponse payload.
    class SendTodoNotificationsService
      RATE_LIMIT_KEY = :mobile_push_notifications
      SUMMARY_SENT_KEY = 'mobile_push:rate_limit_summary_sent:%{user_id}'
      # Same length as the 1-hour period registered for RATE_LIMIT_KEY, but
      # alignment is best effort: the limiter's window starts at its first
      # counted push while this TTL starts at the first breach, so a breach
      # in a closely following window may not produce a fresh summary alert.
      SUMMARY_SENT_TTL = 1.hour

      LATENCY_BUCKETS = [1, 5, 15, 60, 300, 900].freeze

      # ApnsClient result -> `result` label on the counter for per-send outcomes.
      SEND_RESULT_LABELS = {
        delivered: 'delivered',
        bad_token: 'evicted',
        failed: 'failed',
        skipped: 'skipped_not_configured'
      }.freeze

      def initialize(todo_ids)
        @todo_ids = Array(todo_ids)
      end

      def execute
        @results = Hash.new(0)
        @apns_results = Hash.new(0)
        @subscription_count = 0

        todos = Todo.id_in(todo_ids).pending.with_preloaded_user_and_push_subscriptions.to_a

        (todo_ids.size - todos.size).times { record_todo_outcome(:skipped_todo_resolved) }

        todos.each { |todo| process_todo(todo) }

        ServiceResponse.success(payload: {
          todo_count: todo_ids.size,
          subscription_count: @subscription_count,
          results: @results,
          apns_results: @apns_results
        })
      ensure
        @client&.close
      end

      private

      attr_reader :todo_ids

      def process_todo(todo)
        user = todo.user

        return record_todo_outcome(:skipped_user_inactive) unless user&.active?
        return record_todo_outcome(:skipped_setting_disabled) unless Feature.enabled?(:mobile_push_notifications, user)

        subscriptions = user.mobile_device_push_subscriptions.to_a
        return record_todo_outcome(:skipped_no_subscription) if subscriptions.empty?

        @subscription_count += subscriptions.size

        if rate_limited?(user)
          handle_rate_limited(user, subscriptions)
        else
          deliver(todo, subscriptions)
        end
      end

      def deliver(todo, subscriptions)
        results = push_to_all(subscriptions) { |subscription| payload_for(todo, subscription) }

        if results.include?(:delivered)
          observe_latency(todo)
          @results['delivered'] += 1
        else
          @results[results.first.to_s] += 1
        end
      end

      def rate_limited?(user)
        ::Gitlab::ApplicationRateLimiter.throttled?(RATE_LIMIT_KEY, scope: [user])
      end

      # The rate-limited todo alert itself is always suppressed (and counted).
      # The first breach within the window additionally sends one generic
      # summary alert; the SET NX flag keeps every later breach silent until
      # the flag's TTL lapses.
      def handle_rate_limited(user, subscriptions)
        counter.increment(result: 'rate_limited')

        if claim_summary_slot?(user)
          summary = ::Gitlab::MobilePush::SummaryPayload.new(user)
          push_to_all(subscriptions) { summary }
          @results['rate_limited_summary'] += 1
        else
          @results['rate_limited'] += 1
        end
      end

      def claim_summary_slot?(user)
        key = format(SUMMARY_SENT_KEY, user_id: user.id)

        Gitlab::Redis::SharedState.with do |redis|
          redis.set(key, 1, ex: SUMMARY_SENT_TTL.to_i, nx: true)
        end
      end

      def push_to_all(subscriptions)
        subscriptions.map do |subscription|
          result = client.push(subscription, yield(subscription))

          subscription.destroy if result == :bad_token
          counter.increment(result: SEND_RESULT_LABELS.fetch(result, 'failed'))
          @apns_results[result.to_s] += 1

          result
        end
      end

      def client
        @client ||= ::Gitlab::MobilePush::ApnsClient.new
      end

      def payload_for(todo, subscription)
        mode = subscription.id_only_payload? ? :id_only : :full

        @payloads ||= {}
        @payloads[[todo.id, mode]] ||= ::Gitlab::MobilePush::Payload.new(todo, mode: mode)
      end

      def record_todo_outcome(outcome)
        counter.increment(result: outcome.to_s)
        @results[outcome.to_s] += 1
      end

      def counter
        @counter ||= Gitlab::Metrics.counter(
          :mobile_push_notifications_total,
          'Count of mobile push notification processing outcomes'
        )
      end

      def observe_latency(todo)
        latency_histogram.observe({}, Time.current - todo.created_at)
      end

      def latency_histogram
        @latency_histogram ||= Gitlab::Metrics.histogram(
          :mobile_push_notification_delivery_seconds,
          'Latency between todo creation and mobile push delivery',
          {},
          LATENCY_BUCKETS
        )
      end
    end
  end
end
