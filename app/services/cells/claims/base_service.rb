# frozen_string_literal: true

module Cells
  module Claims
    class BaseService
      GRPC_QUERY_TIMEOUT_IN_SECONDS = 10
      GRPC_RETRIES = 3
      GRPC_RETRY_BASE_INTERVAL = 0.5
      GRPC_RETRIABLE_ERRORS = [GRPC::DeadlineExceeded, GRPC::Unavailable].freeze
      MAX_GRPC_MESSAGE_BYTES = 10.megabytes
      # Maximum number of records (creates + destroys) per begin_update call.
      # When Rails has a sparse range and TS has a dense range, list_records may accumulate
      # thousands of records for deletion. Without a per-chunk record cap, a single commit
      # can take too long and exceed the gRPC deadline.
      MAX_RECORDS_PER_CHUNK = 1000
      # Estimated per-record protobuf overhead (subject, source, bucket type, varint framing).
      # The bucket value size is measured separately; this covers the remaining fixed-size fields.
      GRPC_PER_RECORD_OVERHEAD_BYTES = 200

      private

      attr_reader :model

      def claim_service
        @claim_service ||= Gitlab::TopologyServiceClient::ClaimService.instance
      end

      def claimable_model?
        Cells::Claimable.models_with_claims.include?(model)
      end

      def commit_changes(creates: [], destroys: [])
        return 0 if creates.empty? && destroys.empty?

        chunks = chunk_records(creates, destroys)

        chunks.each do |create_chunk, destroy_chunk|
          response = claim_service.begin_update(
            create_records: Cells::TransactionRecord.sanitize_records_for_grpc(create_chunk),
            destroy_records: Cells::TransactionRecord.sanitize_records_for_grpc(destroy_chunk),
            deadline: grpc_deadline
          )

          Retriable.retriable(
            on: GRPC_RETRIABLE_ERRORS, tries: GRPC_RETRIES, base_interval: GRPC_RETRY_BASE_INTERVAL
          ) do
            claim_service.commit_update(response.lease_uuid.value, deadline: grpc_deadline)
          end
        end

        chunks.size
      end

      # Splits create and destroy records into chunks that fit within MAX_GRPC_MESSAGE_BYTES and MAX_RECORDS_PER_CHUNK.
      # Records are processed in order (creates first, then destroys) and packed greedily:
      #   chunk_records([c1, c2], [d1]) => [[[c1, c2], [d1]]]          (single chunk)
      #   chunk_records([big1, big2], []) => [[[big1], []], [[big2], []]] (split)
      #   chunk_records([1, 2, 3, ..., 1001], []) => [[[1, 2, 3, ..., 1000], []], [[1001], []]] (split by count)
      def chunk_records(creates, destroys)
        tagged = creates.map { |r| [:create, r] } + destroys.map { |r| [:destroy, r] }
        chunks = []
        current = { create: [], destroy: [] }
        current_size = 0
        current_count = 0

        tagged.each do |type, record|
          record_size = estimate_record_size(record)

          if current.values.any?(&:present?) &&
              (current_size + record_size > MAX_GRPC_MESSAGE_BYTES || current_count >= MAX_RECORDS_PER_CHUNK)
            chunks << [current[:create], current[:destroy]]
            current = { create: [], destroy: [] }
            current_size = 0
            current_count = 0
          end

          current[type] << record
          current_size += record_size
          current_count += 1
        end

        chunks << [current[:create], current[:destroy]] if current.values.any?(&:present?)
        chunks
      end

      # Conservative estimate: measures the variable-length bucket value and adds a fixed overhead
      # for the remaining protobuf fields (subject, source, bucket type, varint framing).
      # The fixed overhead (GRPC_PER_RECORD_OVERHEAD_BYTES = 200) is intentionally generous to
      # account for variation in other metadata fields without needing full protobuf serialization.
      def estimate_record_size(record)
        bucket_value_size = record.dig(:bucket, :value).to_s.bytesize
        bucket_value_size + GRPC_PER_RECORD_OVERHEAD_BYTES
      end

      def grpc_deadline
        GRPC::Core::TimeConsts.from_relative_time(GRPC_QUERY_TIMEOUT_IN_SECONDS)
      end
    end
  end
end
