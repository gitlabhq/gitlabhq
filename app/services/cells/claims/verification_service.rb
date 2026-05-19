# frozen_string_literal: true

require 'google/protobuf/well_known_types'

module Cells
  module Claims
    class VerificationService < BaseService
      PaginationError = Class.new(RuntimeError)
      DriftError = Class.new(RuntimeError)

      LIMIT = 1000
      RECENTLY_CHANGED_THRESHOLD = 1.hour

      attr_reader :model

      # @param on_batch_processed [Proc] optional callback invoked with the last processed ID after each
      #   successful batch. The worker uses this to persist progress to Redis mid-loop, so that if a later
      #   batch fails the Sidekiq retry resumes from the last successful batch rather than restarting from
      #   the beginning of the run.
      def initialize(model, timeout:, start_id: 0, &on_batch_processed)
        @model = model
        @created_count = 0
        @destroyed_count = 0
        @runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(timeout)
        @start_id = start_id
        @on_batch_processed = on_batch_processed
      end

      def execute
        unless claimable_model?
          Gitlab::AppLogger.warn(
            class: self.class.name,
            message: "#{model.name} model is not claimable, skipping verification",
            feature_category: :cell
          )
          return { created: 0, destroyed: 0, over_time: false, last_id: nil }
        end

        reconcile_claims

        {
          created: @created_count,
          destroyed: @destroyed_count,
          over_time: runtime_limiter.was_over_time?,
          last_id: @scan_last_id
        }
      end

      private

      attr_reader :runtime_limiter

      def reconcile_claims
        start_id = @start_id

        loop do
          batch_started_at = Gitlab::Metrics::System.monotonic_time

          local_records = find_local_records(start_id)
          break if local_records.empty?

          last_id = local_records.last.read_attribute(model.primary_key)
          ts_records = list_ts_records(start_id, last_id)

          created, destroyed, chunk_count = process_batch(local_records, ts_records)

          @scan_last_id = last_id
          @on_batch_processed&.call(@scan_last_id)

          over_time = runtime_limiter.over_time?

          Gitlab::AppLogger.info(
            class: self.class.name,
            message: "Cells::Claims::VerificationService batch processed",
            table_name: model.table_name,
            batch_first_id: start_id,
            batch_last_id: last_id,
            batch_size: local_records.size,
            created: created,
            destroyed: destroyed,
            chunk_count: chunk_count,
            duration_s: Gitlab::Metrics::System.monotonic_time - batch_started_at,
            over_time: over_time,
            cell_id: claim_service.cell_id,
            feature_category: :cell
          )
          break if over_time

          start_id = last_id
        end
      end

      def find_local_records(start_id)
        pk = model.primary_key
        model.cells_claims_scope.where("#{pk} > ?", start_id).order(pk).limit(LIMIT) # rubocop:disable CodeReuse/ActiveRecord -- dynamic model
      end

      def list_ts_records(start_id, end_id)
        records = []
        previous_cursor = nil
        current_start_id_bytes = Cells::Serialization.to_bytes(start_id)
        end_id_bytes = Cells::Serialization.to_bytes(end_id)

        loop do
          response = fetch_ts_records_page(
            model, current_start_id_bytes, end_id_bytes
          )

          records.concat(response.records.to_a)
          break unless response.truncated

          last_id = response.records.last.metadata.source.rails_primary_key_id

          if last_id == previous_cursor
            raise PaginationError, "Pagination cursor did not advance — infinite loop detected in list_ts_records"
          end

          previous_cursor = last_id
          current_start_id_bytes = last_id
        end

        records
      end

      def fetch_ts_records_page(model, start_id_bytes, end_id_bytes)
        Retriable.retriable(on: GRPC_RETRIABLE_ERRORS, tries: GRPC_RETRIES, base_interval: GRPC_RETRY_BASE_INTERVAL) do
          claim_service.list_records(
            source_type: model.cells_claims_source_type,
            bucket_types: model.cells_claims_attributes.values.pluck(:type), # rubocop:disable Database/AvoidUsingPluckWithoutLimit,CodeReuse/ActiveRecord -- not an ActiveRecord relation
            source_id_gt: start_id_bytes,
            source_id_lte: end_id_bytes,
            deadline: grpc_deadline
          )
        end
      end

      def process_batch(local_records, ts_records)
        local_records_by_id = local_records.reject { |r| recently_changed_record?(r) }
          .index_by { |r| Cells::Serialization.to_bytes(r.read_attribute(model.primary_key)) }

        ts_records_by_id = ts_records.group_by { |r| r.metadata.source.rails_primary_key_id }

        creates, destroys = compute_changes(local_records_by_id, ts_records_by_id)
        chunk_count = commit_changes(creates:, destroys:)

        @created_count += creates.size
        @destroyed_count += destroys.size

        [creates.size, destroys.size, chunk_count]
      end

      def compute_changes(local_records_by_id, ts_records_map)
        creates = []
        destroys = []

        local_records_by_id.each do |id, local_record|
          matched_ts_records = ts_records_map.delete(id)

          if matched_ts_records.nil?
            creates.concat(local_record.cells_claims_metadata)
            log_drift(:missing_record_in_topology_service, local_record, nil, nil, nil)
          else
            # exists in both - compare individual claim attributes
            create, destroy = diff_record(local_record, matched_ts_records)
            creates.concat(create)
            destroys.concat(destroy)
          end
        end

        ts_records_map.each_value do |ts_records|
          # exists in TS but missing in local, delete them all
          ts_records.each do |r|
            next if recently_changed_record?(r)

            log_drift(:missing_record_in_local, nil, r.metadata.bucket.type, nil, metadata_from_ts_record(r))
            destroys << metadata_from_ts_record(r)
          end
        end

        [creates, destroys]
      end

      def diff_record(local_record, ts_records)
        return [[], []] if ts_records.any? { |r| recently_changed_record?(r) }

        creates = []
        destroys = []

        local_metadata_by_bucket = local_record.cells_claims_metadata.index_by { |m| m[:bucket][:type] }
        ts_records_by_bucket = ts_records.index_by do |r|
          Cells::Claimable::CLAIMS_BUCKET_TYPE.resolve(r.metadata.bucket.type)
        end

        local_metadata_by_bucket.each do |bucket_type, local_meta|
          ts_record = ts_records_by_bucket.delete(bucket_type)

          if ts_record.nil?
            creates << local_meta
            next
          end

          ts_meta = metadata_from_ts_record(ts_record)
          next if local_meta.except(:record) == ts_meta

          # metadata has changed - destroy old, create new
          log_drift(:changed, local_record, bucket_type, local_meta, ts_meta)
          destroys << ts_meta
          creates << local_meta
        end

        # remaining TS records have no matching local claim attribute
        ts_records_by_bucket.each do |bucket_type, ts_record|
          ts_meta = metadata_from_ts_record(ts_record)
          log_drift(:missing_attribute_in_local, local_record, bucket_type, nil, ts_meta)
          destroys << ts_meta
        end

        [creates, destroys]
      end

      # Checking updated_at covers both recently created and recently updated records
      def recently_changed_record?(record)
        return false unless record.updated_at

        record.updated_at.to_time.after?(RECENTLY_CHANGED_THRESHOLD.ago)
      end

      def log_drift(kind, local_record, bucket_type, local_meta, ts_meta)
        error = DriftError.new("Claims drift detected: #{kind}")
        extra = {
          model: model.name,
          record_id: local_record&.read_attribute(model.primary_key),
          bucket_type: bucket_type,
          local_value: local_meta&.dig(:bucket, :value),
          ts_value: ts_meta&.dig(:bucket, :value),
          feature_category: :cell
        }

        Gitlab::ErrorTracking.track_exception(error, **extra)
      end

      def metadata_from_ts_record(record)
        meta = record.metadata
        {
          bucket: {
            type: Cells::Claimable::CLAIMS_BUCKET_TYPE.resolve(meta.bucket.type),
            value: meta.bucket.value
          },
          subject: {
            type: Cells::Claimable::CLAIMS_SUBJECT_TYPE.resolve(meta.subject.type),
            id: meta.subject.id
          },
          source: {
            type: Cells::Claimable::CLAIMS_SOURCE_TYPE.resolve(meta.source.type),
            rails_primary_key_id: meta.source.rails_primary_key_id
          }
        }
      end
    end
  end
end
