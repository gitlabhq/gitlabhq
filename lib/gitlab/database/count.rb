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

      def self.approximate_count(model)
        return model.count unless Gitlab::Database.postgresql?

        execute_estimate_if_updated_recently(model) || model.count
      end

      def self.execute_estimate_if_updated_recently(model)
        ActiveRecord::Base.connection.select_value(postgresql_estimate_query(model)).to_i if reltuples_updated_recently?(model)
      rescue *CONNECTION_ERRORS
      end

      def self.reltuples_updated_recently?(model)
        time = "to_timestamp(#{1.hour.ago.to_i})"
        query = <<~SQL
          SELECT 1 FROM pg_stat_user_tables WHERE relname = '#{model.table_name}' AND
          (last_vacuum > #{time} OR last_autovacuum > #{time} OR last_analyze > #{time} OR last_autoanalyze > #{time})
        SQL

        ActiveRecord::Base.connection.select_all(query).count > 0
      rescue *CONNECTION_ERRORS
        false
      end

      def self.postgresql_estimate_query(model)
        "SELECT reltuples::bigint AS estimate FROM pg_class where relname = '#{model.table_name}'"
      end
    end
  end
end
