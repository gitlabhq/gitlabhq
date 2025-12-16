# frozen_string_literal: true

module Gitlab
  module Database
    class PgClass < SharedModel
      self.table_name = 'pg_class'

      def self.for_table(relname)
        joins("LEFT JOIN pg_stat_user_tables ON pg_stat_user_tables.relid = pg_class.oid")
          .find_by(Arel.sql("pg_stat_user_tables.relid = to_regclass(?)"), relname)
      end

      def cardinality_estimate
        tuples = reltuples.to_i

        return if tuples < 1

        tuples
      end
    end
  end
end
