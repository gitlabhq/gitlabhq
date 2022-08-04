# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Base class for batched background migrations. Subclasses should implement the `#perform`
    # method as the entry point for the job's execution.
    #
    # Job arguments needed must be defined explicitly,
    # see https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#job-arguments.
    class BatchedMigrationJob
      include Gitlab::Database::DynamicModelHelpers

      def initialize(
        start_id:, end_id:, batch_table:, batch_column:, sub_batch_size:, pause_ms:, job_arguments: [], connection:
      )

        @start_id = start_id
        @end_id = end_id
        @batch_table = batch_table
        @batch_column = batch_column
        @sub_batch_size = sub_batch_size
        @pause_ms = pause_ms
        @job_arguments = job_arguments
        @connection = connection
      end

      def self.job_arguments(*args)
        args.each.with_index do |arg, index|
          define_method(arg) do
            @job_arguments[index]
          end
        end
      end

      def perform
        raise NotImplementedError, "subclasses of #{self.class.name} must implement #{__method__}"
      end

      def batch_metrics
        @batch_metrics ||= Gitlab::Database::BackgroundMigration::BatchMetrics.new
      end

      private

      attr_reader :start_id, :end_id, :batch_table, :batch_column, :sub_batch_size, :pause_ms, :connection

      def each_sub_batch(operation_name: :default, batching_arguments: {}, batching_scope: nil)
        all_batching_arguments = { column: batch_column, of: sub_batch_size }.merge(batching_arguments)

        parent_relation = parent_batch_relation(batching_scope)

        parent_relation.each_batch(**all_batching_arguments) do |relation|
          batch_metrics.instrument_operation(operation_name) do
            yield relation
          end

          sleep([pause_ms, 0].max * 0.001)
        end
      end

      def distinct_each_batch(operation_name: :default, batching_arguments: {})
        all_batching_arguments = { column: batch_column, of: sub_batch_size }.merge(batching_arguments)

        parent_batch_relation.distinct_each_batch(**all_batching_arguments) do |relation|
          batch_metrics.instrument_operation(operation_name) do
            yield relation
          end

          sleep([pause_ms, 0].max * 0.001)
        end
      end

      def parent_batch_relation(batching_scope = nil)
        parent_relation = define_batchable_model(batch_table, connection: connection)
          .where(batch_column => start_id..end_id)

        return parent_relation unless batching_scope

        batching_scope.call(parent_relation)
      end
    end
  end
end
