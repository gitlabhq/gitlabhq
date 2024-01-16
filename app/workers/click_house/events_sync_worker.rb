# frozen_string_literal: true

module ClickHouse
  class EventsSyncWorker
    include ApplicationWorker
    include ClickHouseWorker

    idempotent!
    queue_namespace :cronjob
    data_consistency :delayed
    worker_has_external_dependencies! # the worker interacts with a ClickHouse database
    feature_category :value_stream_management

    def perform
      result = ::ClickHouse::SyncStrategies::EventSyncStrategy.new.execute
      log_extra_metadata_on_done(:result, result)
    end
  end
end
