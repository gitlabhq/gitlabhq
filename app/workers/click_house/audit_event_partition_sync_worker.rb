# frozen_string_literal: true

module ClickHouse
  class AuditEventPartitionSyncWorker
    include ApplicationWorker
    include ClickHouseWorker

    idempotent!
    data_consistency :delayed
    worker_has_external_dependencies! # the worker interacts with a ClickHouse database
    feature_category :compliance_management
    deduplicate :until_executed, including_scheduled: true # The second job can be skipped if first job hasn't run yet.

    def perform(identifier)
      result = ::ClickHouse::SyncStrategies::AuditEventSyncStrategy.new.execute(identifier)
      log_extra_metadata_on_done(:result, result)
    end
  end
end
