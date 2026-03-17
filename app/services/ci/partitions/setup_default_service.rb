# frozen_string_literal: true

module Ci
  module Partitions
    class SetupDefaultService
      def execute
        return if Ci::Partition.current

        setup_default_partitions
      end

      private

      def setup_default_partitions
        setup_active_partitions
        setup_current_partition
      end

      def setup_active_partitions
        ready_partitions = Ci::Partition::DEFAULT_PARTITION_VALUES
          .map { |value| { id: value, status: Ci::Partition.statuses[:ready] } }

        Ci::Partition.upsert_all(ready_partitions, unique_by: :id)
      end

      def setup_current_partition
        Ci::Partition
          .find(Ci::Pipeline.current_partition_value)
          .update!(status: Ci::Partition.statuses[:current], current_from: Time.current)
      end
    end
  end
end
