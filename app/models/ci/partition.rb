# frozen_string_literal: true

module Ci
  class Partition < Ci::ApplicationRecord
    validates :id, :status, presence: true

    state_machine :status, initial: :preparing do
      state :preparing, value: 0
      state :ready, value: 1
      state :current, value: 2
      state :active, value: 3

      event :ready do
        transition preparing: :ready
      end
    end

    scope :id_after, ->(partition_id) { where(arel_table[:id].gt(partition_id)) }

    class << self
      def statuses
        @statuses ||= state_machines[:status].states.to_h { |state| [state.name, state.value] }.freeze
      end

      def current
        with_status(:current).first
      end

      def create_next!
        create!(id: last.id.next, status: statuses[:preparing])
      end
    end

    def above_threshold?(threshold)
      with_ci_connection do
        Ci::Partitionable.registered_models.any? do |model|
          database_partition =  model.partitioning_strategy.partition_for_id(id)
          database_partition && database_partition.data_size > threshold
        end
      end
    end

    def all_partitions_exist?
      with_ci_connection do
        Ci::Partitionable.registered_models.all? do |model|
          model
            .partitioning_strategy
            .partition_for_id(id)
            .present?
        end
      end
    end

    private

    def with_ci_connection(&block)
      Gitlab::Database::SharedModel.using_connection(connection, &block)
    end
  end
end
