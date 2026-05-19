# frozen_string_literal: true

module Ci
  module PartitionableFinder
    extend ActiveSupport::Concern

    class_methods do
      def find_by_id(id)
        return unless id

        partition_id = Ci::Partition.current&.id

        record = find_by(id: id, partition_id: partition_id)
        return record if record

        Gitlab::AppLogger.info(
          Labkit::Fields::CLASS_NAME => name.to_s,
          message: 'Failed to find the record in the current partition',
          record_id: id
        )

        active_partitions = Ci::Partition.with_status(:active).order(id: :desc).limit(3).pluck(:id)
        record = find_by(id: id, partition_id: active_partitions)
        return record if record

        Gitlab::AppLogger.info(
          Labkit::Fields::CLASS_NAME => name.to_s,
          message: 'Failed to find the record in the latest active partitions',
          record_id: id
        )

        find_by(id: id)
      end
    end
  end
end
