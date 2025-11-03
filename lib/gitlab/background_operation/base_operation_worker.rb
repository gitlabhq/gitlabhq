# frozen_string_literal: true

module Gitlab
  module BackgroundOperation
    # Base class for batched background operation. Subclasses should implement the `#perform`
    # method as the entry point for the job's execution.

    # rubocop:disable Metrics/ParameterLists -- Need a lot of args
    # rubocop:disable CodeReuse/ActiveRecord -- Need to manipulate active record object
    class BaseOperationWorker
      include Gitlab::Database::DynamicModelHelpers
      include Gitlab::ClassAttributes

      DEFAULT_FEATURE_CATEGORY = :database
      MINIMUM_PAUSE_MS = 100

      class << self
        def operation_name(operation)
          define_method(:operation_name) do
            operation
          end
        end

        def job_arguments(*args)
          args.each_with_index do |arg, index|
            define_method(arg) do
              @job_arguments[index]
            end
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
          cursor_columns.count >= 1
        end

        def cursor(*args)
          define_singleton_method(:cursor_columns) do
            args
          end
        end
      end

      def initialize(
        batch_table:, batch_column:, sub_batch_size:, pause_ms:, connection:, job_arguments: [],
        min_cursor: nil, max_cursor: nil, sub_batch_exception: nil
      )
        @min_cursor = min_cursor
        @max_cursor = max_cursor
        @batch_table = batch_table
        @batch_column = batch_column
        @sub_batch_size = sub_batch_size
        @pause_ms = [pause_ms, MINIMUM_PAUSE_MS].max
        @job_arguments = job_arguments
        @connection = connection
        @sub_batch_exception = sub_batch_exception
      end

      def perform
        raise NotImplementedError, "subclasses of #{self.class.name} must implement #{__method__}"
      end

      def batch_metrics
        @batch_metrics ||= Gitlab::Database::Batch::Metrics.new
      end

      private

      attr_reader :min_cursor, :max_cursor, :batch_table, :batch_column, :sub_batch_size,
        :pause_ms, :connection, :sub_batch_exception

      delegate :cursor_columns, :cursor?, to: :'self.class'

      def each_sub_batch(batching_arguments: {})
        all_batching_arguments = { load_batch: false, of: sub_batch_size }.merge(batching_arguments)

        sub_batch_relation.each_batch(**all_batching_arguments) do |sub_batch|
          batch_metrics.instrument_operation(operation_name) do
            yield sub_batch
          rescue *Gitlab::Database::BackgroundOperation::Job::TIMEOUT_EXCEPTIONS => exception
            exception_class = sub_batch_exception || exception.class

            raise exception_class, exception
          end

          sleep(pause_ms * 0.001)
        end
      end

      def base_relation
        model_class = define_batchable_model(batch_table, primary_key: fetch_primary_key, connection: connection)
        cursor_expression = Arel::Nodes::Grouping.new(cursor_columns.map { |column| model_class.arel_table[column] })
        cursor_gteq_start = cursor_expression.gteq(arel_for_cursor(min_cursor, model_class.arel_table))
        cursor_lteq_end = cursor_expression.lteq(arel_for_cursor(max_cursor, model_class.arel_table))
        where_condition = Arel::Nodes::And.new([cursor_gteq_start, cursor_lteq_end])
        model_class.where(where_condition)
      end

      def arel_for_cursor(cursor, arel_table)
        Arel::Nodes::Grouping.new(
          cursor_columns.zip(cursor).map do |column, value|
            Arel::Nodes.build_quoted(value, arel_table[column])
          end
        )
      end

      def sub_batch_relation
        base_class = Gitlab::Database.application_record_for_connection(connection)
        model_class = define_batchable_model(batch_table, connection: connection, base_class: base_class)
        order = model_class.order(cursor_columns) # rubocop:disable CodeReuse/ActiveRecord -- To refactor in a follow up
        keyset_order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(order)
        Gitlab::Pagination::Keyset::Iterator.new(scope: base_relation.order(keyset_order))
      end

      def fetch_primary_key
        connection.primary_keys(batch_table)
      end

      def operation_name
        raise('Operation name is required, please define it with `operation_name`') unless respond_to?(:operation_name)
      end

      def cursor
        raise('Cursor is required, please define it with `cursor`') if cursor_columns.empty?
      end
    end
    # rubocop:enable Metrics/ParameterLists
    # rubocop:enable CodeReuse/ActiveRecord
  end
end
