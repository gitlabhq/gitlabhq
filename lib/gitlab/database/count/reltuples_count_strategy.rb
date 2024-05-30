# frozen_string_literal: true

module Gitlab
  module Database
    module Count
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

        private

        # Models using single-type inheritance (STI) don't work with
        # reltuple count estimates. We just have to ignore them and
        # use another strategy to compute them.
        def non_sti_models(models)
          models.reject { |model| sti_model?(model) }
        end

        def non_sti_table_names(models)
          non_sti_models(models).map(&:table_name)
        end

        def sti_model?(model)
          model.column_names.include?(model.inheritance_column) &&
            model.base_class != model
        end

        def table_to_model_mapping
          @table_to_model_mapping ||= models.index_by(&:table_name)
        end

        def table_to_model(table_name)
          table_to_model_mapping[table_name]
        end

        def size_estimates(check_statistics: true)
          results = {}

          models.group_by { |model| model.connection_db_config.name }.map do |db_name, models_for_db|
            base_model = Gitlab::Database.database_base_models[db_name]
            tables = non_sti_table_names(models_for_db)

            # Querying tuple stats only works on the primary. Due to load balancing, the
            # easiest way to do this is to start a transaction.
            base_model.transaction do
              Gitlab::Database::SharedModel.using_connection(base_model.connection) do
                get_statistics(tables, check_statistics: check_statistics).each do |row|
                  model = table_to_model(row.table_name)
                  results[model] = row.estimate
                end
              end
            end
          end

          results
        end

        # Generates the PostgreSQL query to return the tuples for tables
        # that have been vacuumed or analyzed in the last hour.
        #
        # @param [Array] table names
        # @returns [Hash] Table name to count mapping (e.g. { 'projects' => 5, 'users' => 100 })
        def get_statistics(table_names, check_statistics: true)
          time = 6.hours.ago

          query = ::Gitlab::Database::PgClass.joins("LEFT JOIN pg_stat_user_tables ON pg_stat_user_tables.relid = pg_class.oid")
            .where(relname: table_names)
            .where('schemaname = current_schema()')
            .select('pg_class.relname AS table_name, reltuples::bigint AS estimate')

          if check_statistics
            query = query.where('last_vacuum > ? OR last_autovacuum > ? OR last_analyze > ? OR last_autoanalyze > ?',
              time, time, time, time)
          end

          query
        end
      end
    end
  end
end
