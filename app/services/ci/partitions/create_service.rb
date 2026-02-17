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
        return unless headroom_available?

        Ci::Partition.create_next!
      end

      private

      attr_reader :partition

      def headroom_available?
        Ci::Partition.id_after(partition.id).count < HEADROOM_PARTITIONS
      end
    end
  end
end
