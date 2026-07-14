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
      # With `fallback: false`, only the partition-pruned records are returned
      # and the full-table scan is skipped. This is useful when the caller
      # (e.g. ActiveRecord's Preloader via `available_records:`) already loads
      # the remaining ids itself, so we avoid issuing a duplicate scan here.
      #
      # Returns an Array<Ci::Pipeline>.
      class BulkByIdLookup
        def initialize(ids, fallback: true)
          @ids = Array.wrap(ids).compact.uniq
          @fallback = fallback
        end

        def execute
          return [] if ids.empty?

          found = find_in_partitions
          return found unless fallback

          @missing_ids = ids - found.map(&:id)
          found + full_scan
        end

        private

        attr_reader :ids, :missing_ids, :fallback

        def find_in_partitions
          partition_ids = PartitionCache.partition_ids_for(ids)

          if partition_ids.empty?
            log_cache_miss
            return []
          end

          ::Ci::Pipeline.in_partition(partition_ids).id_in(ids).to_a
        end

        def full_scan
          return [] if missing_ids.empty?

          log_full_table_scan

          ::Ci::Pipeline.id_in(missing_ids).to_a
        end

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
