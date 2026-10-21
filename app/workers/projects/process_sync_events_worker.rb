# frozen_string_literal: true

module Projects
  # This worker can be called multiple times at the same time but only one of them can
  # process events at a time. This is ensured by `try_obtain_lease` in `Database::ProcessSyncEventsService`.
  # `until_executing` here is to reduce redundant worker enqueuing.
  class ProcessSyncEventsWorker
    include ApplicationWorker

    data_consistency :always

    feature_category :cell
    urgency :high

    idempotent!
    deduplicate :until_executed, if_deduplicated: :reschedule_once, ttl: 1.minute

    def perform
      results = ::Database::ProcessSyncEventsService.new(
        ::Projects::SyncEvent, sync_classes_by_consumer
      ).execute

      results.merge!(::Database::CleanupSyncEventsService.new(::Projects::SyncEvent).execute)

      results.each do |key, value|
        log_extra_metadata_on_done(key, value)
      end
    end

    private

    def sync_classes_by_consumer
      { ci: ::Ci::ProjectMirror, sec: ::Security::ProjectMirror }
    end
  end
end
