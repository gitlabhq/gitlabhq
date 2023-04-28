# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      module List
        class ConvertTable
          UnableToPartition = Class.new(StandardError)

          SQL_STATEMENT_SEPARATOR = ";\n\n"

          PARTITIONING_CONSTRAINT_NAME = 'partitioning_constraint'

          attr_reader :partitioning_column, :table_name, :parent_table_name, :zero_partition_value,
            :locking_configuration

          def initialize(
            migration_context:, table_name:, parent_table_name:, partitioning_column:,
            zero_partition_value:, lock_tables: [])

            @migration_context = migration_context
            @connection = migration_context.connection
            @table_name = table_name
            @parent_table_name = parent_table_name
            @partitioning_column = partitioning_column
            @zero_partition_value = zero_partition_value
            @locking_configuration = LockingConfiguration.new(migration_context, table_locking_order: lock_tables)
          end

          def prepare_for_partitioning(async: false)
            assert_existing_constraints_partitionable

            add_partitioning_check_constraint(async: async)
          end

          def revert_preparation_for_partitioning
            migration_context.remove_check_constraint(table_name, partitioning_constraint.name)
          end

          def partition
            assert_existing_constraints_partitionable
            assert_partitioning_constraint_present

            create_parent_table
            attach_foreign_keys_to_parent

            locking_configuration.with_lock_retries do
              redefine_loose_foreign_key_triggers do
                migration_context.execute(sql_to_convert_table)
              end
            end
          end

          def revert_partitioning
            migration_context.with_lock_retries(raise_on_exhaustion: true) do
              migration_context.execute(<<~SQL)
              ALTER TABLE #{connection.quote_table_name(parent_table_name)}
              DETACH PARTITION #{connection.quote_table_name(table_name)};
              SQL

              alter_sequences_sql = alter_sequence_statements(old_table: parent_table_name, new_table: table_name)
                                      .join(SQL_STATEMENT_SEPARATOR)

              migration_context.execute(alter_sequences_sql)

              # This takes locks for all the foreign keys that the parent table had.
              # However, those same locks were taken while detaching the partition, and we can't avoid that.
              # If we dropped the foreign key before detaching the partition to avoid this locking,
              # the drop would cascade to the child partitions and drop their foreign keys as well
              migration_context.drop_table(parent_table_name)
            end

            add_partitioning_check_constraint
          end

          private

          attr_reader :connection, :migration_context

          delegate :quote_table_name, :quote_column_name, :current_schema, to: :connection

          def sql_to_convert_table
            # The critical statement here is the attach_table_to_parent statement.
            # The following statements could be run in a later transaction,
            # but they acquire the same locks so it's much faster to include them
            # here.
            [
              locking_configuration.locking_statement_for(tables_that_will_lock_during_partitioning),
              attach_table_to_parent_statement,
              alter_sequence_statements(old_table: table_name, new_table: parent_table_name),
              remove_constraint_statement
            ].flatten.join(SQL_STATEMENT_SEPARATOR)
          end

          def table_identifier
            "#{current_schema}.#{table_name}"
          end

          def assert_existing_constraints_partitionable
            violating_constraints = Gitlab::Database::PostgresConstraint
                                      .by_table_identifier(table_identifier)
                                      .primary_or_unique_constraints
                                      .not_including_column(partitioning_column)
                                      .to_a

            return if violating_constraints.empty?

            violation_messages = violating_constraints.map { |c| "#{c.name} on (#{c.column_names.join(', ')})" }

            raise UnableToPartition, <<~MSG
            Constraints on #{table_name} are incompatible with partitioning on #{partitioning_column}

            All primary key and unique constraints must include the partitioning column.
            Violations:
            #{violation_messages.join("\n")}
            MSG
          end

          def partitioning_constraint
            constraints_on_column = Gitlab::Database::PostgresConstraint
                                      .by_table_identifier(table_identifier)
                                      .check_constraints
                                      .including_column(partitioning_column)

            check_body = "CHECK ((#{partitioning_column} = #{zero_partition_value}))"

            constraints_on_column.find do |constraint|
              constraint.definition.start_with?(check_body)
            end
          end

          def assert_partitioning_constraint_present
            return if partitioning_constraint&.constraint_valid?

            raise UnableToPartition, <<~MSG
            Table #{table_name} is not ready for partitioning.
            Before partitioning, a check constraint must enforce that (#{partitioning_column} = #{zero_partition_value})
            MSG
          end

          def add_partitioning_check_constraint(async: false)
            return validate_partitioning_constraint_synchronously if partitioning_constraint.present?

            check_body = "#{partitioning_column} = #{connection.quote(zero_partition_value)}"
            # Any constraint name would work. The constraint is found based on its definition before partitioning
            migration_context.add_check_constraint(
              table_name, check_body, PARTITIONING_CONSTRAINT_NAME,
              validate: !async
            )

            if async
              migration_context.prepare_async_check_constraint_validation(
                table_name, name: PARTITIONING_CONSTRAINT_NAME
              )
            end

            return if partitioning_constraint.present?

            raise UnableToPartition, <<~MSG
            Error adding partitioning constraint `#{PARTITIONING_CONSTRAINT_NAME}` for `#{table_name}`
            MSG
          end

          def validate_partitioning_constraint_synchronously
            if partitioning_constraint.constraint_valid?
              return Gitlab::AppLogger.info <<~MSG
              Nothing to do, the partitioning constraint exists and is valid for `#{table_name}`
              MSG
            end

            # Async validations are executed only on .com, we need to validate synchronously for self-managed
            migration_context.validate_check_constraint(table_name, partitioning_constraint.name)
            return if partitioning_constraint.constraint_valid?

            raise UnableToPartition, <<~MSG
            Error validating partitioning constraint `#{partitioning_constraint.name}` for `#{table_name}`
            MSG
          end

          def create_parent_table
            migration_context.execute(<<~SQL)
            CREATE TABLE IF NOT EXISTS #{quote_table_name(parent_table_name)} (
                LIKE #{quote_table_name(table_name)} INCLUDING ALL
            ) PARTITION BY LIST(#{quote_column_name(partitioning_column)})
            SQL
          end

          def attach_foreign_keys_to_parent
            migration_context.foreign_keys(table_name).each do |fk|
              # At this point no other connection knows about the parent table.
              # Thus the only contended lock in the following transaction is on fk.to_table.
              # So a deadlock is impossible.

              # If we're rerunning this migration after a failure to acquire a lock, the foreign key might already exist
              # Don't try to recreate it in that case
              if migration_context.foreign_keys(parent_table_name)
                                  .any? { |p_fk| p_fk.options[:name] == fk.options[:name] }
                next
              end

              migration_context.with_lock_retries(raise_on_exhaustion: true) do
                migration_context.add_foreign_key(parent_table_name, fk.to_table, **fk.options)
              end
            end
          end

          def attach_table_to_parent_statement
            <<~SQL
              ALTER TABLE #{quote_table_name(parent_table_name)}
              ATTACH PARTITION #{table_name}
              FOR VALUES IN (#{zero_partition_value})
            SQL
          end

          def alter_sequence_statements(old_table:, new_table:)
            sequences_owned_by(old_table).map do |seq_info|
              seq_name, column_name = seq_info.values_at(:name, :column_name)

              statement_parts = []

              # If a different user owns the old table, the conversion process will fail to reassign the sequence
              # ownership to the new parent table (as it will be owned by the current user).
              # Force the old table to be owned by the current user in that case.
              unless current_user_owns_table?(old_table)
                statement_parts << set_current_user_owns_table_statement(old_table)
              end

              statement_parts << <<~SQL.chomp
              ALTER SEQUENCE #{quote_table_name(seq_name)} OWNED BY #{quote_table_name(new_table)}.#{quote_column_name(column_name)}
              SQL

              statement_parts.join(SQL_STATEMENT_SEPARATOR)
            end
          end

          def remove_constraint_statement
            <<~SQL
            ALTER TABLE #{quote_table_name(parent_table_name)}
            DROP CONSTRAINT #{quote_table_name(partitioning_constraint.name)}
            SQL
          end

          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/373887
          def sequences_owned_by(table_name)
            sequence_data = connection.exec_query(<<~SQL, nil, [table_name])
            SELECT seq_pg_class.relname AS seq_name,
                   dep_pg_class.relname AS table_name,
                   pg_attribute.attname AS col_name
            FROM pg_class seq_pg_class
                 INNER JOIN pg_depend ON seq_pg_class.oid = pg_depend.objid
                 INNER JOIN pg_class dep_pg_class ON pg_depend.refobjid = dep_pg_class.oid
                 INNER JOIN pg_attribute ON dep_pg_class.oid = pg_attribute.attrelid
                                         AND pg_depend.refobjsubid = pg_attribute.attnum
            WHERE seq_pg_class.relkind = 'S'
              AND dep_pg_class.relname = $1
            SQL

            sequence_data.map do |seq_info|
              name, column_name = seq_info.values_at('seq_name', 'col_name')
              { name: name, column_name: column_name }
            end
          end

          def table_owner(table_name)
            connection.select_value(<<~SQL, nil, [table_name])
            SELECT tableowner FROM pg_tables WHERE tablename = $1
            SQL
          end

          def current_user_owns_table?(table_name)
            current_user = connection.select_value('select current_user')
            table_owner(table_name) == current_user
          end

          def set_current_user_owns_table_statement(table_name)
            <<~SQL.chomp
            ALTER TABLE #{connection.quote_table_name(table_name)} OWNER TO CURRENT_USER
            SQL
          end

          def table_name_for_identifier(table_identifier)
            /^\w+\.(\w+)*$/.match(table_identifier)[1]
          end

          def redefine_loose_foreign_key_triggers
            if migration_context.has_loose_foreign_key?(table_name)
              migration_context.untrack_record_deletions(table_name)

              yield if block_given?

              migration_context.track_record_deletions(parent_table_name)
              migration_context.track_record_deletions(table_name)
            elsif block_given?
              yield
            end
          end

          def tables_that_will_lock_during_partitioning
            # Locks are taken against the table + all tables that reference it by foreign key
            # postgres_foreign_keys.referenced_table_name gives the table name that we need here directly, but that
            # column did not exist yet during the migration 20221021145820_create_routing_table_for_builds_metadata_v2
            # To ensure compatibility with that migration if it is run with this code, use referenced_table_identifier
            # here.
            referenced_tables = Gitlab::Database::PostgresForeignKey
                                  .by_constrained_table_identifier(table_identifier)
                                  .map { |fk| table_name_for_identifier(fk.referenced_table_identifier) }
            referenced_tables + [table_name]
          end
        end
      end
    end
  end
end
