# frozen_string_literal: true

# rubocop:disable Sidekiq/EnforceDatabaseHealthSignalDeferral -- latency-sensitive, tiny DB load, see class comment
module Todos
  # Delivers APNs push notifications for a batch of freshly created todos:
  # one job per TodoService#create_todos call. Batching keeps the enqueue and
  # the todo/user/subscription loading O(1) in the number of recipients.
  # Delivery lives in Notifications::MobilePush::SendTodoNotificationsService;
  # this worker only runs it and logs the returned tallies.
  #
  # Not deferred on database health signals: those indicators are instance-wide
  # and would hold time-sensitive pushes back for minutes, while this job reads
  # a few rows by id from a replica and writes only on device token eviction.
  class PushNotificationWorker
    include ApplicationWorker

    data_consistency :delayed
    feature_category :notifications
    urgency :low
    worker_has_external_dependencies!
    idempotent!

    def perform(todo_ids)
      response = ::Notifications::MobilePush::SendTodoNotificationsService.new(todo_ids).execute

      response.payload.each do |key, value|
        log_extra_metadata_on_done(key, value)
      end
    end
  end
end
# rubocop:enable Sidekiq/EnforceDatabaseHealthSignalDeferral
