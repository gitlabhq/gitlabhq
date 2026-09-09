# frozen_string_literal: true

module Todos
  # Delivers APNs push notifications for a batch of freshly created todos:
  # one job per TodoService#create_todos call. Batching keeps the enqueue and
  # the todo/user/subscription loading O(1) in the number of recipients.
  # Delivery lives in Notifications::MobilePush::SendTodoNotificationsService;
  # this worker only runs it and logs the returned tallies.
  class PushNotificationWorker
    include ApplicationWorker

    data_consistency :delayed
    feature_category :notifications
    urgency :low
    worker_has_external_dependencies!
    # The health-signal deferral keeps the database-wide indicators (WAL,
    # Patroni apdex) as an incident lever, but deliberately leaves `todos`
    # out of the autovacuum table list: this job reads a handful of todo rows
    # by primary key from a replica and never writes to `todos`, so it cannot
    # compete with a vacuum there, and autovacuum on a table that size runs
    # often enough that including it held every push back (doubling up to 30
    # minutes per hop) until the notification was no longer timely. The only
    # table it writes to is the subscriptions table, on token eviction.
    defer_on_database_health_signal :gitlab_main, [:mobile_device_push_subscriptions], 1.minute
    idempotent!

    def perform(todo_ids)
      response = ::Notifications::MobilePush::SendTodoNotificationsService.new(todo_ids).execute

      response.payload.each do |key, value|
        log_extra_metadata_on_done(key, value)
      end
    end
  end
end
