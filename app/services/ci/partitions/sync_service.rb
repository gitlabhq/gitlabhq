# frozen_string_literal: true

module Ci
  module Partitions
    class SyncService
      def initialize(partition)
        @partition = partition
      end

      def execute
        return unless partition

        sync_available_partitions_statuses!

        next_ci_partition = next_available_partition
        return unless next_ci_partition.present? && partition.exceed_time_window?

        next_ci_partition.switch_writes!
        update_range_id_boundaries(next_ci_partition)
      end

      private

      attr_reader :partition

      def sync_available_partitions_statuses!
        Ci::Partition.id_after(partition.id).with_status(:preparing).each do |record|
          record.ready! if record.all_partitions_exist?
        end
      end

      def next_available_partition
        Ci::Partition.next_available(partition.id)
      end

      # Uses the builds because querying p_ci_pipelines for partition_id = ANY(100, 101, 102)
      # would time out since we have a single partition that spans those values
      # gitlab_partitions_dynamic.ci_pipelines FOR VALUES IN ('100', '101', '102')
      def update_range_id_boundaries(incoming)
        min, max = CommitStatus.in_partition(partition.id).pick('MIN(commit_id), MAX(commit_id)')
        return unless max

        partition.update!(pipelines_id_range: min...max)
        incoming.update!(pipelines_id_range: (max.next...))
      end
    end
  end
end
