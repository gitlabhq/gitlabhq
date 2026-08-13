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
    defer_on_database_health_signal :gitlab_main, [:todos, :mobile_device_push_subscriptions], 1.minute
    idempotent!

    def perform(todo_ids)
      response = ::Notifications::MobilePush::SendTodoNotificationsService.new(todo_ids).execute

      response.payload.each do |key, value|
        log_extra_metadata_on_done(key, value)
      end
    end
  end
end
