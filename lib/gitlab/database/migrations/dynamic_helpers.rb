# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module DynamicHelpers
        DYNAMIC_SCHEMA = Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA

        def move_table_to_dynamic_schema(table_name)
          execute(<<~SQL)
            ALTER TABLE IF EXISTS #{table_name} SET SCHEMA #{DYNAMIC_SCHEMA};
          SQL
        end

        def move_table_from_dynamic_schema(
          table_name, partition_values:, parent_table_name:
        )
          table_identifier = "#{DYNAMIC_SCHEMA}.#{table_name}"

          if table_exists?(table_identifier)
            execute(<<~SQL)
              ALTER TABLE IF EXISTS #{table_identifier} SET SCHEMA #{connection.current_schema};
            SQL
          else
            remove_dynamic_partitions(
              table_name, partition_values: partition_values, parent_table_name: parent_table_name
            )

            execute(<<~SQL)
              CREATE TABLE IF NOT EXISTS #{table_name} PARTITION OF #{parent_table_name}
                FOR VALUES IN (#{partition_values.to_a.join(', ')});
            SQL
          end
        end

        private

        def remove_dynamic_partitions(table_name, partition_values:, parent_table_name:)
          partition_values.each do |value|
            identifier = "#{DYNAMIC_SCHEMA}.#{table_name}_#{value}"
            next unless table_exists?(identifier)

            execute(<<~SQL)
              ALTER TABLE #{parent_table_name} DETACH PARTITION #{identifier};
              DROP TABLE IF EXISTS #{identifier};
            SQL
          end
        end
      end
    end
  end
end
