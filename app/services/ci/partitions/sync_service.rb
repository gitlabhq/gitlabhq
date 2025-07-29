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
        return unless next_ci_partition.present? && above_threshold?

        next_ci_partition.switch_writes!
      end

      private

      attr_reader :partition

      def above_threshold?
        partition.above_threshold?
      end

      def sync_available_partitions_statuses!
        Ci::Partition.id_after(partition.id).with_status(:preparing).each do |record|
          record.ready! if record.all_partitions_exist?
        end
      end

      def next_available_partition
        Ci::Partition.next_available(partition.id)
      end
    end
  end
end
