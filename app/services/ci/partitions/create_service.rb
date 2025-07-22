# frozen_string_literal: true

module Ci
  module Partitions
    class CreateService
      HEADROOM_PARTITIONS = 2

      def initialize(partition)
        @partition = partition
      end

      def execute
        return unless partition

        Ci::Partition.create_next! if should_create_next?
      end

      private

      attr_reader :partition

      def should_create_next?
        above_threshold? && headroom_available?
      end

      def above_threshold?
        partition.above_threshold?
      end

      def headroom_available?
        Ci::Partition.id_after(partition.id).count < HEADROOM_PARTITIONS
      end
    end
  end
end
