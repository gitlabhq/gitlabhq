# frozen_string_literal: true

require 'csv'

# Create a csv with all the pg settings

module Gitlab
  module Database
    module Sos
      class PgConstraints
        def self.run(output)
          query_results = ApplicationRecord.connection.execute <<~SQL
                          SELECT
                            c.relname AS table_name,
                            con.conname AS constraint_name,
                            pg_get_constraintdef(con.oid) AS constraint_definition
                          FROM
                            pg_constraint con
                          JOIN
                            pg_class c ON c.oid = con.conrelid
                          WHERE
                            con.convalidated = false
                          ORDER BY
                            c.relname, con.conname;
          SQL

          output.write_file('pg_constraints.csv') do |f|
            CSV.open(f, 'w+') do |csv|
              # headers [table_name, constraint_name, constraint_definition]
              csv << query_results.fields
              # data
              query_results.each do |row|
                csv << row.values
              end
            end
          end
        end
      end
    end
  end
end
