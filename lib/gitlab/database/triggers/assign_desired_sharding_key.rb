# frozen_string_literal: true

module Gitlab
  module Database
    module Triggers
      class AssignDesiredShardingKey
        include Gitlab::Database::SchemaHelpers

        attr_reader :name

        delegate :execute, :quote_table_name, :quote_column_name, to: :connection, private: true

        def initialize(
          table:, sharding_key:, parent_table:, parent_sharding_key:,
          foreign_key:, connection:, parent_table_primary_key: nil, trigger_name: nil
        )
          @table = table
          @sharding_key = sharding_key
          @parent_table = parent_table
          @parent_table_primary_key = parent_table_primary_key
          @parent_sharding_key = parent_sharding_key
          @foreign_key = foreign_key
          @name = trigger_name || generated_name
          @connection = connection
        end

        def create
          quoted_table_name = quote_table_name(table)
          quoted_parent_table = quote_table_name(parent_table)
          quoted_sharding_key = quote_column_name(sharding_key)
          quoted_parent_sharding_key = quote_column_name(parent_sharding_key)
          quoted_primary_key = quote_column_name(parent_table_primary_key || 'id')
          quoted_foreign_key = quote_column_name(foreign_key)

          create_trigger_function(name) do
            <<~SQL
              IF NEW.#{quoted_sharding_key} IS NULL THEN
                SELECT #{quoted_parent_sharding_key}
                INTO NEW.#{quoted_sharding_key}
                FROM #{quoted_parent_table}
                WHERE #{quoted_parent_table}.#{quoted_primary_key} = NEW.#{quoted_foreign_key};
              END IF;

              RETURN NEW;
            SQL
          end

          # Postgres 14 adds the `OR REPLACE` option to trigger creation, so
          # this line can be removed and `OR REPLACE` added to `#create_trigger`
          # when the minimum supported version is updated to 14 (milestone 17.0).
          drop_trigger(quoted_table_name, name)

          create_trigger(quoted_table_name, name, name, fires: 'BEFORE INSERT OR UPDATE')
        end

        def drop
          drop_trigger(quote_table_name(table), name)
          drop_function(name)
        end

        private

        attr_reader :table, :sharding_key, :parent_table, :parent_table_primary_key, :parent_sharding_key,
          :foreign_key, :connection

        def generated_name
          identifier = "#{table}_assign_#{sharding_key}"

          "trigger_#{Digest::SHA256.hexdigest(identifier).first(12)}"
        end
      end
    end
  end
end
