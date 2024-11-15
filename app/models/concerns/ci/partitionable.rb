# frozen_string_literal: true

module Ci
  ##
  # This module implements a way to set the `partition_id` value on a dependent
  # resource from a parent record.
  # Usage:
  #
  #     class PipelineVariable < Ci::ApplicationRecord
  #       include Ci::Partitionable
  #
  #       belongs_to :pipeline
  #       partitionable scope: :pipeline
  #       # Or
  #       partitionable scope: ->(record) { record.partition_value }
  #
  #
  module Partitionable
    extend ActiveSupport::Concern
    include ::Gitlab::Utils::StrongMemoize

    included do
      Partitionable::Testing.check_inclusion(self)

      before_validation :set_partition_id, on: :create
      validates :partition_id, presence: true

      scope :in_partition, ->(id, partition_foreign_key: :partition_id) do
        where(partition_id: (id.respond_to?(partition_foreign_key) ? id.try(partition_foreign_key) : id))
      end

      def set_partition_id
        return if partition_id_changed? && partition_id.present?
        return unless partition_scope_value

        self.partition_id = partition_scope_value
      end
    end

    def self.registered_models
      Gitlab::Database::Partitioning
        .registered_models
        .select { |model| model < Ci::ApplicationRecord && model < Ci::Partitionable }
    end

    class_methods do
      def partitionable(scope:, through: nil, partitioned: false)
        handle_partitionable_through(through)
        handle_partitionable_scope(scope)
        handle_partitionable_ddl(partitioned)
      end

      private

      def handle_partitionable_through(options)
        return unless options
        return if Gitlab::Utils.to_boolean(ENV['DISABLE_PARTITIONABLE_SWITCH'], default: false)

        define_singleton_method(:routing_table_name) { options[:table] }
        define_singleton_method(:routing_table_name_flag) { options[:flag] }

        include Partitionable::Switch
      end

      def handle_partitionable_scope(scope)
        define_method(:partition_scope_value) do
          strong_memoize(:partition_scope_value) do
            next Ci::Pipeline.current_partition_value if respond_to?(:importing?) && importing?

            record = scope.to_proc.call(self)
            record.respond_to?(:partition_id) ? record.partition_id : record
          end
        end
      end

      def handle_partitionable_ddl(partitioned)
        return unless partitioned

        include ::PartitionedTable

        partitioned_by :partition_id,
          strategy: :ci_sliding_list,
          next_partition_if: ->(latest_partition) do
            latest_partition.blank? || create_database_partition?(latest_partition)
          end,
          detach_partition_if: proc { false },
          analyze_interval: 3.days
      end

      def create_database_partition?(database_partition)
        if Feature.enabled?(:ci_partitioning_automation, :instance)
          Ci::Partition.provisioning(database_partition.values.max).present?
        else
          database_partition.before?(Ci::Partition::LATEST_PARTITION_VALUE)
        end
      end
    end
  end
end
