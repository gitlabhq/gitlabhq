# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Base class for batched background migrations. Subclasses should implement the `#perform`
    # method as the entry point for the job's execution.
    #
    # Job arguments needed must be defined explicitly,
    # see https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#use-job-arguments.
    # rubocop:disable Metrics/ClassLength
    # rubocop:disable Metrics/ParameterLists
    class BatchedMigrationJob
      include Gitlab::Database::DynamicModelHelpers
      include Gitlab::ClassAttributes

      DEFAULT_FEATURE_CATEGORY = :database

      class << self
        def generic_instance(batch_table:, batch_column:, connection:, job_arguments: [])
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

        def cursor_columns
          []
        end

        def cursor?
          cursor_columns.count > 1
        end

        def cursor(*args)
          define_singleton_method(:cursor_columns) do
            args
          end
        end
      end

      def initialize(
        batch_table:, batch_column:, sub_batch_size:, pause_ms:, connection:, job_arguments: [],
        start_id: nil, end_id: nil, start_cursor: nil, end_cursor: nil, sub_batch_exception: nil
      )

        @start_id = start_id
        @end_id = end_id
        @start_cursor = start_cursor
        @end_cursor = end_cursor
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

      attr_reader :start_id, :end_id, :start_cursor, :end_cursor, :batch_table, :batch_column, :sub_batch_size,
        :pause_ms, :connection, :sub_batch_exception

      delegate :cursor_columns, :cursor?, to: :'self.class'

      def each_sub_batch(batching_arguments: {}, batching_scope: nil)
        base_batching_arguments = if cursor?
                                    { load_batch: false }
                                  else
                                    { column: batch_column }
                                  end

        all_batching_arguments = { of: sub_batch_size }.merge(base_batching_arguments, batching_arguments)

        sub_batch_relation(batching_scope: batching_scope).each_batch(**all_batching_arguments) do |sub_batch|
          batch_metrics.instrument_operation(operation_name) do
            yield sub_batch
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
        if cursor?
          model_class = define_batchable_model(batch_table, connection: connection)

          cursor_expression = Arel::Nodes::Grouping.new(
            cursor_columns.map { |column| model_class.arel_table[column] }
          )

          cursor_gteq_start = cursor_expression.gteq(arel_for_cursor(start_cursor, model_class.arel_table))
          cursor_lteq_end = cursor_expression.lteq(arel_for_cursor(end_cursor, model_class.arel_table))

          where_condition = Arel::Nodes::And.new([cursor_gteq_start, cursor_lteq_end])

          model_class.where(where_condition)
        else
          define_batchable_model(batch_table, connection: connection, primary_key: batch_column)
            .where(batch_column => start_id..end_id)
        end
      end

      def arel_for_cursor(cursor, arel_table)
        Arel::Nodes::Grouping.new(
          cursor_columns.zip(cursor).map do |column, value|
            Arel::Nodes.build_quoted(value, arel_table[column])
          end
        )
      end

      def filter_sub_batch(relation, batching_scope = nil)
        return relation unless batching_scope

        batching_scope.call(relation)
      end

      def sub_batch_relation(batching_scope: nil)
        if cursor?
          base_class = Gitlab::Database.application_record_for_connection(connection)
          model_class = define_batchable_model(batch_table, connection: connection, base_class: base_class)
          order = model_class.order(cursor_columns)
          keyset_order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(order)
          sub_batch_relation = Gitlab::Pagination::Keyset::Iterator.new(scope: base_relation.order(keyset_order))
        else
          relation = filter_batch(base_relation)
          sub_batch_relation = filter_sub_batch(relation, batching_scope)
        end

        sub_batch_relation
      end

      def operation_name
        raise('Operation name is required, please define it with `operation_name`') unless cursor?
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/ParameterLists
