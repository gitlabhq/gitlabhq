# frozen_string_literal: true

require 'google/protobuf/well_known_types'

module Cells
  module Leases
    class ReconciliationService
      # | Local  / Remote -> | Active     | Stale      | Missing      |
      # |--------------------|------------|------------|--------------|
      # | **Active**         | No-op      | No-op      | No-op        |
      # | **Stale**          | Commit     | Commit     | Delete local |
      # | **Missing**        | No-op      | Roll back  | Ignore       |

      # A lease is considered stale if not updated in the last 5 minutes
      LEASE_STALENESS_THRESHOLD = 5.minutes
      # Number of leases to process per batch when paginating through remote leases
      LIMIT = 100
      # Local leases older than 1 hour are forcibly deleted as orphaned
      ORPHANED_LEASE_CLEANUP_THRESHOLD = 1.hour

      TIMEOUT_IN_SECONDS = 1

      def initialize
        @claim_service = Gitlab::TopologyServiceClient::ClaimService.instance
        @processed_count = 0
        @committed_count = 0
        @rolled_back_count = 0
        @pending_count = 0
        @orphaned_count = 0
        @ts_lease_uuids = Set.new
      end

      def execute
        reconcile_leases
        cleanup_orphaned_leases

        {
          processed: @processed_count,
          committed: @committed_count,
          rolled_back: @rolled_back_count,
          pending: @pending_count,
          orphaned: @orphaned_count
        }
      end

      private

      attr_reader :claim_service

      # Fetches all remote leases from the Topology Service and reconciles them with local state.
      # Uses cursor-based pagination to handle large numbers of leases efficiently.
      # Tracks all Topology Service lease UUIDs for orphaned cleanup.
      def reconcile_leases
        cursor = nil

        loop do
          response = claim_service.list_leases(cursor: cursor, limit: LIMIT, deadline: grpc_deadline)
          ts_leases = response.leases
          break if ts_leases.empty?

          # Track all Topology Service lease UUIDs we've seen
          @ts_lease_uuids.merge(ts_leases.map { |lease| lease.uuid.value })

          # Fetch all relevant local leases in a single query for efficiency
          rails_leases = fetch_rails_leases(ts_leases)

          # Find leases that are only present on TS
          ts_only_leases = ts_leases.reject { |lease| rails_leases.include?(lease.uuid.value) }

          # Further categorize leases by staleness
          lease_staleness_threshold = LEASE_STALENESS_THRESHOLD.ago
          ts_stale_leases = ts_only_leases.select { |lease| lease.updated_at.to_time < lease_staleness_threshold }
          rails_stale_leases = rails_leases.each_value.select { |lease| lease.updated_at < lease_staleness_threshold }

          # Reconcile each category
          @committed_count += commit_rails_leases(rails_stale_leases)
          @rolled_back_count += rollback_lost_leases(ts_stale_leases)
          @processed_count += ts_leases.size
          @pending_count += ts_only_leases.size - ts_stale_leases.size

          cursor = response.next
          break if cursor.blank?
        end
      end

      def commit_rails_leases(leases)
        committed_uuids = []

        leases.each do |lease|
          claim_service.commit_update(lease.uuid, deadline: grpc_deadline)
          committed_uuids << lease.uuid
        rescue StandardError => e
          track_error(e, lease.uuid)
        end

        Cells::OutstandingLease.delete(committed_uuids)
      end

      def rollback_lost_leases(leases)
        leases.count do |lease|
          claim_service.rollback_update(lease.uuid.value, deadline: grpc_deadline)
          log_lease(lease, 'Rolled back stale lost lease')
          true
        rescue StandardError => e
          track_error(e, lease.uuid.value)
          false
        end
      end

      def fetch_rails_leases(leases)
        lease_uuid_values = leases.map { |lease| lease.uuid.value }
        Cells::OutstandingLease.by_uuid(lease_uuid_values).index_by(&:uuid)
      end

      # Deletes local leases that are stale and don't exist in the Topology service.
      def cleanup_orphaned_leases
        cutoff_time = ORPHANED_LEASE_CLEANUP_THRESHOLD.ago
        Cells::OutstandingLease.updated_before(cutoff_time).each_batch(of: LIMIT) do |batch|
          # Only delete leases that don't exist on Topology service
          orphaned_leases = batch.reject { |lease| @ts_lease_uuids.include?(lease.uuid) }

          next if orphaned_leases.empty?

          orphaned_lease_uuids = orphaned_leases.map(&:uuid)
          @orphaned_count += Cells::OutstandingLease.delete(orphaned_lease_uuids)

          log_orphaned_cleanup(orphaned_lease_uuids, cutoff_time)
        end
      rescue StandardError => e
        track_error(e, nil)
      end

      def grpc_deadline
        GRPC::Core::TimeConsts.from_relative_time(TIMEOUT_IN_SECONDS)
      end

      def track_error(exception, uuid)
        Gitlab::ErrorTracking.track_exception(exception, feature_category: :cell, lease_uuid: uuid)
      end

      def log_lease(lease, message)
        Gitlab::AppLogger.info(
          message: message,
          lease_uuid: lease.uuid.value,
          lease_updated_at: lease.updated_at.to_time,
          staleness_duration: Time.current - lease.updated_at.to_time,
          cell_id: claim_service.cell_id,
          feature_category: :cell
        )
      end

      def log_orphaned_cleanup(orphaned_lease_uuids, cutoff_time)
        Gitlab::AppLogger.info(
          message: 'Cleaned up orphaned leases (stale locally, missing remotely)',
          lease_uuids: orphaned_lease_uuids,
          deleted_count: orphaned_lease_uuids.size,
          cutoff_time: cutoff_time,
          cell_id: claim_service.cell_id,
          feature_category: :cell
        )
      end
    end
  end
end
