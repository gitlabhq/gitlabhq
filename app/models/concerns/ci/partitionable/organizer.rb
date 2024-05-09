# frozen_string_literal: true

module Ci
  module Partitionable
    module Organizer
      extend ActiveSupport::Concern

      class << self
        include ::Gitlab::Utils::StrongMemoize

        def new_partition_required?(latest_partition_id)
          insert_first_partitions if Feature.enabled?(:ci_partitioning_first_records)

          Ci::Pipeline::NEXT_PARTITION_VALUE > latest_partition_id
        end

        private

        def insert_first_partitions
          Ci::Partition.upsert_all(
            [
              { id: Ci::Pipeline::INITIAL_PARTITION_VALUE },
              { id: Ci::Pipeline::SECOND_PARTITION_VALUE },
              { id: Ci::Pipeline::NEXT_PARTITION_VALUE }
            ],
            unique_by: :id
          )
        end
        strong_memoize_attr :insert_first_partitions
      end
    end
  end
end
