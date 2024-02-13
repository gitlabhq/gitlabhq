# frozen_string_literal: true

module ClickHouse
  class AuditEventsSyncWorker
    include ApplicationWorker
    include ClickHouseWorker

    idempotent!
    queue_namespace :cronjob
    data_consistency :delayed
    worker_has_external_dependencies! # the worker interacts with a ClickHouse database
    feature_category :compliance_management

    def perform
      return unless enabled?

      partition_identifiers.each do |identifier|
        ::ClickHouse::AuditEventPartitionSyncWorker.perform_async(identifier)
      end
    end

    private

    def partition_identifiers
      ::Gitlab::Database::PostgresPartition.for_parent_table(:audit_events).map(&:identifier)
    end

    def enabled?
      Gitlab::ClickHouse.configured? && Feature.enabled?(:sync_audit_events_to_clickhouse,
        type: :gitlab_com_derisk)
    end
  end
end
