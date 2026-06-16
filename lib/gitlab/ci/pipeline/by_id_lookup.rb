# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      # Resolves a Ci::Pipeline by id using PartitionCache to prune by
      # partition_id, falling back to a full-table scan when:
      #   - no cached range covers the id (cache cold/stale or id outside any range), or
      #   - the partition-pruned query returns nothing.
      #
      class ByIdLookup
        def initialize(scope, id)
          @scope = scope
          @id = id
        end

        def execute
          return if id.blank?

          find_in_partitions || full_scan
        end

        private

        attr_reader :scope, :id

        # rubocop:disable CodeReuse/ActiveRecord -- partition-aware lookup is intentionally co-located here
        def find_in_partitions
          partition_ids = PartitionCache.partition_ids_for(id)

          if partition_ids.empty?
            log_cache_miss
            return
          end

          scope.find_by(id: id, partition_id: partition_ids)
        end

        def full_scan
          log_full_table_scan

          scope.find_by(id: id)
        end
        # rubocop:enable CodeReuse/ActiveRecord

        def log_cache_miss
          Gitlab::AppLogger.info(
            Labkit::Fields::CLASS_NAME => ::Ci::Pipeline.name,
            message: 'PartitionCache has no range covering pipeline id, falling back to full scan',
            record_id: id
          )
        end

        def log_full_table_scan
          Gitlab::AppLogger.info(
            Labkit::Fields::CLASS_NAME => ::Ci::Pipeline.name,
            message: 'Partition-pruned query missed, falling back to full scan',
            record_id: id
          )
        end
      end
    end
  end
end
