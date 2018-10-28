# frozen_string_literal: true

# For large tables, PostgreSQL can take a long time to count rows due to MVCC.
# We can optimize this by using the reltuples count as described in https://wiki.postgresql.org/wiki/Slow_Counting.
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
      # counts for them.  If the model's table has not been vacuumed or
      # analyzed recently, simply run the Model.count to get the data.
      #
      # @param [Array]
      # @return [Hash] of Model -> count mapping
      def self.approximate_counts(models, strategies: [ReltuplesCountStrategy, ExactCountStrategy])
        strategies.each_with_object({}) do |strategy, counts_by_model|
          if strategy.enabled?
            models_with_missing_counts = models - counts_by_model.keys
            counts = strategy.new(models_with_missing_counts).count

            counts.each do |model, count|
              counts_by_model[model] = count
            end
          end
        end
      end

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

      class ReltuplesCountStrategy
        attr_reader :models
        def initialize(models)
          @models = models
        end

        # Returns a hash of the table names that have recently updated tuples.
        #
        # @returns [Hash] Table name to count mapping (e.g. { 'projects' => 5, 'users' => 100 })
        def count
          query = postgresql_estimate_query(table_names)
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
        rescue *CONNECTION_ERRORS => e
          {}
        end

        def self.enabled?
          Gitlab::Database.postgresql?
        end

        private

        def table_names
          models.map(&:table_name)
        end

        # Generates the PostgreSQL query to return the tuples for tables
        # that have been vacuumed or analyzed in the last hour.
        #
        # @param [Array] table names
        # @returns [Hash] Table name to count mapping (e.g. { 'projects' => 5, 'users' => 100 })
        def postgresql_estimate_query(table_names)
          time = "to_timestamp(#{1.hour.ago.to_i})"
          <<~SQL
          SELECT pg_class.relname AS table_name, reltuples::bigint AS estimate FROM pg_class
          LEFT JOIN pg_stat_user_tables ON pg_class.relname = pg_stat_user_tables.relname
          WHERE pg_class.relname IN (#{table_names.map { |table| "'#{table}'" }.join(',')})
          AND (last_vacuum > #{time} OR last_autovacuum > #{time} OR last_analyze > #{time} OR last_autoanalyze > #{time})
          SQL
        end
      end
    end
  end
end
