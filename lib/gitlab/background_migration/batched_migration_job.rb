# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Base class for batched background migrations. Subclasses should implement the `#perform`
    # method as the entry point for the job's execution.
    #
    # Job arguments needed must be defined explicitly,
    # see https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#job-arguments.
    # rubocop:disable Metrics/ClassLength
    # rubocop:disable Metrics/ParameterLists
    class BatchedMigrationJob
      include Gitlab::Database::DynamicModelHelpers
      include Gitlab::ClassAttributes

      DEFAULT_FEATURE_CATEGORY = :database

      class << self
        def generic_instance(batch_table:, batch_column:, job_arguments: [], connection:)
          new(
            batch_table: batch_table, batch_column: batch_column,
            job_arguments: job_arguments, connection: connection,
            start_id: 0, end_id: 0, sub_batch_size: 0, pause_ms: 0
          )
        end

        def job_arguments_count
          0
        end

        def operation_name(operation)
          define_method(:operation_name) do
            operation
          end
        end

        def job_arguments(*args)
          args.each.with_index do |arg, index|
            define_method(arg) do
              @job_arguments[index]
            end
          end

          define_singleton_method(:job_arguments_count) do
            args.count
          end
        end

        def scope_to(scope)
          define_method(:filter_batch) do |relation|
            instance_exec(relation, &scope)
          end
        end

        def feature_category(feature_category_name = nil)
          if feature_category_name.present?
            set_class_attribute(:feature_category, feature_category_name)
          else
            get_class_attribute(:feature_category) || DEFAULT_FEATURE_CATEGORY
          end
        end
      end

      def initialize(
        start_id:, end_id:, batch_table:, batch_column:, sub_batch_size:, pause_ms:, job_arguments: [], connection:,
        sub_batch_exception: nil
      )

        @start_id = start_id
        @end_id = end_id
        @batch_table = batch_table
        @batch_column = batch_column
        @sub_batch_size = sub_batch_size
        @pause_ms = pause_ms
        @job_arguments = job_arguments
        @connection = connection
        @sub_batch_exception = sub_batch_exception
      end

      def filter_batch(relation)
        relation
      end

      def perform
        raise NotImplementedError, "subclasses of #{self.class.name} must implement #{__method__}"
      end

      def batch_metrics
        @batch_metrics ||= Gitlab::Database::BackgroundMigration::BatchMetrics.new
      end

      private

      attr_reader :start_id, :end_id, :batch_table, :batch_column, :sub_batch_size,
        :pause_ms, :connection, :sub_batch_exception

      def each_sub_batch(batching_arguments: {}, batching_scope: nil)
        all_batching_arguments = { column: batch_column, of: sub_batch_size }.merge(batching_arguments)

        relation = filter_batch(base_relation)
        sub_batch_relation = filter_sub_batch(relation, batching_scope)

        sub_batch_relation.each_batch(**all_batching_arguments) do |relation|
          batch_metrics.instrument_operation(operation_name) do
            yield relation
          rescue *Gitlab::Database::BackgroundMigration::BatchedJob::TIMEOUT_EXCEPTIONS => exception
            exception_class = sub_batch_exception || exception.class

            raise exception_class, exception
          end

          sleep([pause_ms, 0].max * 0.001)
        end
      end

      def distinct_each_batch(batching_arguments: {})
        if base_relation != filter_batch(base_relation)
          raise 'distinct_each_batch can not be used when additional filters are defined with scope_to'
        end

        all_batching_arguments = { column: batch_column, of: sub_batch_size }.merge(batching_arguments)

        base_relation.distinct_each_batch(**all_batching_arguments) do |relation|
          batch_metrics.instrument_operation(operation_name) do
            yield relation
          end

          sleep([pause_ms, 0].max * 0.001)
        end
      end

      def base_relation
        define_batchable_model(batch_table, connection: connection)
          .where(batch_column => start_id..end_id)
      end

      def filter_sub_batch(relation, batching_scope = nil)
        return relation unless batching_scope

        batching_scope.call(relation)
      end

      def operation_name
        raise('Operation name is required, please define it with `operation_name`')
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/ParameterLists
