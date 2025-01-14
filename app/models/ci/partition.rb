# frozen_string_literal: true

module Ci
  class Partition < Ci::ApplicationRecord
    MAX_PARTITION_SIZE = 100.gigabytes

    INITIAL_PARTITION_VALUE = 100
    LATEST_PARTITION_VALUE = 102
    DEFAULT_PARTITION_VALUES = (INITIAL_PARTITION_VALUE..LATEST_PARTITION_VALUE).to_a.freeze

    validates :id, :status, presence: true
    validates :status, uniqueness: { if: ->(partition) { partition.status_changed? && partition.current? } }

    state_machine :status, initial: :preparing do
      state :preparing, value: 0
      state :ready, value: 1
      state :current, value: 2
      state :active, value: 3

      event :ready do
        transition preparing: :ready
      end

      event :switch_writes do
        transition [:ready, :active] => :current
      end

      before_transition any => :current do
        Ci::Partition.with_status(:current).update_all(status: Ci::Partition.statuses[:active])
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

      def next_available(partition_id)
        Ci::Partition
          .with_status(:ready)
          .id_after(partition_id)
          .order(id: :asc)
          .first
      end

      def provisioning(partition_id)
        Ci::Partition
          .with_status(:preparing)
          .id_after(partition_id)
          .order(id: :asc)
          .first
      end
    end

    def above_threshold?(threshold)
      with_ci_connection do
        Gitlab::Database::PostgresPartition
          .with_parent_tables(parent_table_names)
          .with_list_constraint(id)
          .above_threshold(threshold)
          .exists?
      end
    end

    def all_partitions_exist?
      with_ci_connection do
        Gitlab::Database::PostgresPartition
          .with_parent_tables(parent_table_names)
          .with_list_constraint(id)
          .count == parent_table_names.size
      end
    end

    private

    def with_ci_connection(&block)
      Gitlab::Database::SharedModel.using_connection(connection, &block)
    end

    def parent_table_names
      Ci::Partitionable.registered_models.map(&:table_name)
    end
  end
end
