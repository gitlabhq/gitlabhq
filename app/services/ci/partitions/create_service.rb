# frozen_string_literal: true

module Ci
  module Partitions
    class CreateService
      HEADROOM_PARTITIONS = 1

      def initialize(partition)
        @partition = partition
      end

      def execute
        return unless partition
        return unless headroom_available?

        Ci::Partition.create_next!
      end

      private

      attr_reader :partition

      def headroom_available?
        Ci::Partition.id_after(headroom_base).count < HEADROOM_PARTITIONS
      end

      # While the write target is still within the static default partitions
      # (100..102), measure headroom from the last static partition instead of
      # from the current one, so a partition past 102 (i.e. 103) is created from
      # any of 100/101/102.
      def headroom_base
        return Ci::Partition::LAST_STATIC_PARTITION_VALUE if static_partition?

        partition.id
      end

      def static_partition?
        Ci::Partition::DEFAULT_PARTITION_VALUES.include?(partition.id)
      end
    end
  end
end
