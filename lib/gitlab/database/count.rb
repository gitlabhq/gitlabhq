# frozen_string_literal: true

# For large tables, PostgreSQL can take a long time to count rows due to MVCC.
# We can optimize this by using various strategies for approximate counting.
#
# For example, we can use the reltuples count as described in https://wiki.postgresql.org/wiki/Slow_Counting.
#
# However, since statistics are not always up to date, we also implement a table sampling strategy
# that performs an exact count but only on a sample of the table. See TablesampleCountStrategy.
module Gitlab
  module Database
    module Count
      CONNECTION_ERRORS =
        if defined?(PG)
          [
            ActionView::Template::Error,
            ActiveRecord::StatementInvalid,
            PG::Error
          ].freeze
        else
          [
            ActionView::Template::Error,
            ActiveRecord::StatementInvalid
          ].freeze
        end

      # Takes in an array of models and returns a Hash for the approximate
      # counts for them.
      #
      # Various count strategies can be specified that are executed in
      # sequence until all tables have an approximate count attached
      # or we run out of strategies.
      #
      # Note that not all strategies are available on all supported RDBMS.
      #
      # @param [Array]
      # @return [Hash] of Model -> count mapping
      def self.approximate_counts(models, strategies: [TablesampleCountStrategy, ReltuplesCountStrategy, ExactCountStrategy])
        strategies.each_with_object({}) do |strategy, counts_by_model|
          if strategy.enabled?
            models_with_missing_counts = models - counts_by_model.keys

            return counts_by_model if models_with_missing_counts.empty?

            counts = strategy.new(models_with_missing_counts).count

            counts.each do |model, count|
              counts_by_model[model] = count
            end
          end
        end
      end

      # This strategy performs an exact count on the model.
      #
      # This is guaranteed to be accurate, however it also scans the
      # whole table. Hence, there are no guarantees with respect
      # to runtime.
      #
      # Note that for very large tables, this may even timeout.
      class ExactCountStrategy
        attr_reader :models
        def initialize(models)
          @models = models
        end

        def count
          models.each_with_object({}) do |model, data|
            data[model] = model.count
          end
        end

        def self.enabled?
          true
        end
      end

      # This strategy counts based on PostgreSQL's statistics in pg_stat_user_tables.
      #
      # Specifically, it relies on the column reltuples in said table. An additional
      # check is performed to make sure statistics were updated within the last hour.
      #
      # Otherwise, this strategy skips tables with outdated statistics.
      #
      # There are no guarantees with respect to the accuracy of this strategy. Runtime
      # however is guaranteed to be "fast", because it only looks up statistics.
      class ReltuplesCountStrategy
        attr_reader :models
        def initialize(models)
          @models = models
        end

        # Returns a hash of the table names that have recently updated tuples.
        #
        # @returns [Hash] Table name to count mapping (e.g. { 'projects' => 5, 'users' => 100 })
        def count
          size_estimates
        rescue *CONNECTION_ERRORS
          {}
        end

        def self.enabled?
          Gitlab::Database.postgresql?
        end

        private

        def table_names
          models.map(&:table_name)
        end

        def size_estimates(check_statistics: true)
          query = postgresql_estimate_query(table_names, check_statistics: check_statistics)
          rows = []

          # Querying tuple stats only works on the primary. Due to load
          # easiest way to do this is to start a transaction.
          ActiveRecord::Base.transaction do
            rows = ActiveRecord::Base.connection.select_all(query)
          end

          table_to_model = models.each_with_object({}) { |model, h| h[model.table_name] = model }

          rows.each_with_object({}) do |row, data|
            model = table_to_model[row['table_name']]
            data[model] = row['estimate'].to_i
          end
        end

        # Generates the PostgreSQL query to return the tuples for tables
        # that have been vacuumed or analyzed in the last hour.
        #
        # @param [Array] table names
        # @returns [Hash] Table name to count mapping (e.g. { 'projects' => 5, 'users' => 100 })
        def postgresql_estimate_query(table_names, check_statistics: true)
          time = "to_timestamp(#{1.hour.ago.to_i})"
          base_query = <<~SQL
          SELECT pg_class.relname AS table_name, reltuples::bigint AS estimate FROM pg_class
          LEFT JOIN pg_stat_user_tables ON pg_class.relname = pg_stat_user_tables.relname
          WHERE pg_class.relname IN (#{table_names.map { |table| "'#{table}'" }.join(',')})
          SQL
          if check_statistics
            base_query + "AND (last_vacuum > #{time} OR last_autovacuum > #{time} OR last_analyze > #{time} OR last_autoanalyze > #{time})"
          else
            base_query
          end
        end
      end

      # A tablesample count executes in two phases:
      # * Estimate table sizes based on reltuples.
      # * Based on the estimate:
      #   * If the table is considered 'small', execute an exact relation count.
      #   * Otherwise, count on a sample of the table using TABLESAMPLE.
      #
      # The size of the sample is chosen in a way that we always roughly scan
      # the same amount of rows (see TABLESAMPLE_ROW_TARGET).
      #
      # There are no guarantees with respect to the accuracy of the result or runtime.
      class TablesampleCountStrategy < ReltuplesCountStrategy
        EXACT_COUNT_THRESHOLD = 100_000
        TABLESAMPLE_ROW_TARGET = 100_000

        def count
          estimates = size_estimates(check_statistics: false)

          models.each_with_object({}) do |model, count_by_model|
            count = perform_count(model, estimates[model])
            count_by_model[model] = count if count
          end
        rescue *CONNECTION_ERRORS
          {}
        end

        private
        def perform_count(model, estimate)
          # If we estimate 0, we may not have statistics at all. Don't use them.
          return nil unless estimate && estimate > 0

          if estimate < EXACT_COUNT_THRESHOLD
            # The table is considered small, the assumption here is that
            # the exact count will be fast anyways.
            model.count
          else
            # The table is considered large, let's only count on a sample.
            tablesample_count(model, estimate)
          end
        end

        def tablesample_count(model, estimate)
          portion = (TABLESAMPLE_ROW_TARGET.to_f / estimate).round(4)
          inverse = 1/portion
          query = <<~SQL
            SELECT (COUNT(*)*#{inverse})::integer AS count
            FROM #{model.table_name} TABLESAMPLE SYSTEM (#{portion*100})
          SQL

          rows = ActiveRecord::Base.connection.select_all(query)

          Integer(rows.first['count'])
        end
      end
    end
  end
end
