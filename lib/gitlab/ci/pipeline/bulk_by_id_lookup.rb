# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      # Bulk analogue of Gitlab::Ci::Pipeline::ByIdLookup.
      #
      # Resolves a list of pipeline ids to Ci::Pipeline records using
      # PartitionCache to prune by partition_id, falling back to a
      # full-table scan for ids the cache cannot resolve.
      #
      # Issues at most two SQL roundtrips:
      #
      #   1. WHERE id IN (...) AND partition_id IN (cached partition_ids)
      #   2. WHERE id IN (still_missing_ids) -- full cross-partition scan.
      #
      # Each fallback logs the count of ids that fell through.
      #
      # Returns a Hash<Integer, Ci::Pipeline> keyed by pipeline id.
      class BulkByIdLookup
        def initialize(ids)
          @ids = Array.wrap(ids).compact.uniq
        end

        def execute
          return {} if ids.empty?

          found = find_in_partitions
          @missing_ids = ids - found.keys
          found.merge!(full_scan)
          found
        end

        private

        attr_reader :ids, :missing_ids

        # rubocop:disable CodeReuse/ActiveRecord -- partition-pruning queries are intentionally co-located here
        def find_in_partitions
          partition_ids = PartitionCache.partition_ids_for(ids)

          if partition_ids.empty?
            log_cache_miss
            return {}
          end

          ::Ci::Pipeline.where(id: ids, partition_id: partition_ids).index_by(&:id)
        end

        def full_scan
          return {} if missing_ids.empty?

          log_full_table_scan

          ::Ci::Pipeline.where(id: missing_ids).index_by(&:id)
        end
        # rubocop:enable CodeReuse/ActiveRecord

        def log_cache_miss
          Gitlab::AppLogger.info(
            Labkit::Fields::CLASS_NAME => ::Ci::Pipeline.name,
            message: 'PartitionCache has no range covering pipeline ids, falling back to full scan',
            missing_record_count: ids.size
          )
        end

        def log_full_table_scan
          Gitlab::AppLogger.info(
            Labkit::Fields::CLASS_NAME => ::Ci::Pipeline.name,
            message: 'Partition-pruned query missed, falling back to full scan',
            missing_record_count: missing_ids.size
          )
        end
      end
    end
  end
end
