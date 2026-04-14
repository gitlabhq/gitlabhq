# frozen_string_literal: true

module Ci
  module PartitionableFinder
    extend ActiveSupport::Concern

    class_methods do
      def find_by_id(id)
        return find_by(id: id) unless Feature.enabled?(:ci_partitionable_finder, :current_request)

        partition_id = Ci::Partition.current&.id

        find_by(id: id, partition_id: partition_id) || find_by(id: id)
      end
    end
  end
end
