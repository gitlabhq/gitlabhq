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
      def self.approximate_counts(models)
        table_to_model_map = models.each_with_object({}) do |model, hash|
          hash[model.table_name] = model
        end

        table_names = table_to_model_map.keys
        counts_by_table_name = Gitlab::Database.postgresql? ? reltuples_from_recently_updated(table_names) : {}

        # Convert table -> count to Model -> count
        counts_by_model = counts_by_table_name.each_with_object({}) do |pair, hash|
          model = table_to_model_map[pair.first]
          hash[model] = pair.second
        end

        missing_tables = table_names - counts_by_table_name.keys

        missing_tables.each do |table|
          model = table_to_model_map[table]
          counts_by_model[model] = model.count
        end

        counts_by_model
      end

      # Returns a hash of the table names that have recently updated tuples.
      #
      # @param [Array] table names
      # @returns [Hash] Table name to count mapping (e.g. { 'projects' => 5, 'users' => 100 })
      def self.reltuples_from_recently_updated(table_names)
        query = postgresql_estimate_query(table_names)
        rows = []

        # Querying tuple stats only works on the primary. Due to load
        # balancing, we need to ensure this query hits the load balancer.  The
        # easiest way to do this is to start a transaction.
        ActiveRecord::Base.transaction do
          rows = ActiveRecord::Base.connection.select_all(query)
        end

        rows.each_with_object({}) { |row, data| data[row['table_name']] = row['estimate'].to_i }
      rescue *CONNECTION_ERRORS
        {}
      end

      # Generates the PostgreSQL query to return the tuples for tables
      # that have been vacuumed or analyzed in the last hour.
      #
      # @param [Array] table names
      # @returns [Hash] Table name to count mapping (e.g. { 'projects' => 5, 'users' => 100 })
      def self.postgresql_estimate_query(table_names)
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
