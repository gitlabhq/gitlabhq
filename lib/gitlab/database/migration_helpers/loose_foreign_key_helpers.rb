# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      module LooseForeignKeyHelpers
        include Gitlab::Database::SchemaHelpers

        POSTGRES_IDENTIFIER_LIMIT = 63

        INSERT_FUNCTION_NAME = 'insert_into_loose_foreign_keys_deleted_records'
        INSERT_FUNCTION_NAME_OVERRIDE_TABLE = 'insert_into_loose_foreign_keys_deleted_records_override_table'
        INSERT_FUNCTION_NAME_CUSTOM_COLUMN = 'insert_into_loose_foreign_keys_deleted_records_with'

        # Maps the table referenced by a `db/docs` sharding key to the deleted-records table
        # that deleted rows are routed to, and to the sharding key column on it. This is the
        # only place the routing is defined: the trigger function receives the resolved target
        # and stays generic. Sharding keys referencing any other table are not routable and
        # fall back to the cell-local loose_foreign_keys_deleted_records table.
        # See https://gitlab.com/gitlab-org/gitlab/-/work_items/597949
        SHARDING_KEY_TARGETS = {
          'organizations' => { table: 'loose_foreign_keys_organization_deleted_records', column: 'organization_id' },
          'namespaces' => { table: 'loose_foreign_keys_namespace_deleted_records', column: 'namespace_id' },
          'projects' => { table: 'loose_foreign_keys_project_deleted_records', column: 'project_id' },
          'users' => { table: 'loose_foreign_keys_user_deleted_records', column: 'user_id' }
        }.freeze

        # This adds a LFK standard trigger to tables, where the loose_foreign_keys_deleted_records
        # record is referencing the table. This should be used for non-partitioned tables.
        def track_record_deletions(table_name)
          trigger_name = record_deletion_trigger_name(table_name)

          execute(<<~SQL.squish)
            CREATE TRIGGER #{trigger_name}
            AFTER DELETE ON #{table_name} REFERENCING OLD TABLE AS old_table
            FOR EACH STATEMENT
            EXECUTE FUNCTION #{INSERT_FUNCTION_NAME}();
          SQL
        end

        # This is used to track deletions on partitioned tables and their partitions.
        # parent_table is the table name that is insert into loose_foreign_keys_deleted_records table
        # it defaults to the table_name, and that's for when we track deletions on partitioned (parent) tables.
        def track_record_deletions_override_table_name(table_identifier, parent_table = nil)
          table_name = table_identifier.to_s.split('.').last
          parent_table ||= table_name

          execute(<<~SQL.squish)
            CREATE TRIGGER #{record_deletion_trigger_name(table_name)}
            AFTER DELETE ON #{table_identifier} REFERENCING OLD TABLE AS old_table
            FOR EACH STATEMENT
            EXECUTE FUNCTION
            #{INSERT_FUNCTION_NAME_OVERRIDE_TABLE}(#{connection.quote(parent_table)});
          SQL
        end

        # This method also works on tables that are not in the default schema, but
        # the full table identifier has to be passed in this case.
        def untrack_record_deletions(table, trigger_name: nil)
          trigger_name ||= record_deletion_trigger_name(table)
          drop_trigger(table, trigger_name)
        end

        def has_loose_foreign_key?(table)
          trigger_exists?(table, record_deletion_trigger_name(table))
        end

        # Whether the partitioned parent's LFK trigger already routes deleted records by
        # sharding key. Partitioned tables always use the override-table trigger function:
        # argument 1 is the parent table name, argument 2 the routing targets when present.
        def partitioned_record_deletions_routed_by_sharding_keys?(parent_table)
          record_deletion_trigger_nargs(parent_table).to_i >= 2
        end

        # Installs on a partition the trigger form its parent currently uses, so partitions
        # of a routed parent route as well and everything else keeps the cell-local form.
        def track_record_deletions_for_partition(partition_identifier, parent_table)
          if partitioned_record_deletions_routed_by_sharding_keys?(parent_table)
            track_record_deletions_override_table_name_with_sharding_keys(partition_identifier, parent_table)
          else
            track_record_deletions_override_table_name(partition_identifier, parent_table)
          end
        end

        def track_record_deletions_with_custom_column(
          table, column:, parent_table: nil,
          function_name: nil, trigger_name: nil)
          table_name = table.to_s.split('.').last
          parent_table ||= table_name

          function_name ||= "#{INSERT_FUNCTION_NAME_CUSTOM_COLUMN}_#{column}"
          trigger_name ||= record_deletion_trigger_name(table_name)

          validate_identifier_length!(function_name)
          validate_identifier_length!(trigger_name)
          validate_column_uniqueness!(table, column)

          create_trigger_function(function_name, replace: true) do
            <<~SQL
              INSERT INTO loose_foreign_keys_deleted_records
              (fully_qualified_table_name, primary_key_value)
              SELECT current_schema() || '.' || TG_ARGV[0], old_table.#{connection.quote_column_name(column)}
              FROM old_table;

              RETURN NULL;
            SQL
          end

          execute(<<~SQL)
            CREATE TRIGGER #{trigger_name}
            AFTER DELETE ON #{table}
            REFERENCING OLD TABLE AS old_table
            FOR EACH STATEMENT
            EXECUTE FUNCTION #{function_name}(#{connection.quote(parent_table)});
          SQL
        end

        # TEMPORARY (Phase 3/4 of https://gitlab.com/gitlab-org/gitlab/-/work_items/597949): creates or rewrites the
        # LFK trigger on a non-partitioned table so deleted records are routed to the sharding-key-specific tables.
        # Sharding keys are read from the table's `db/docs` entry. With no routable sharding key, the trigger behaves
        # exactly like `track_record_deletions` (records stay cell-local). This will replace `track_record_deletions`
        # once every trigger is migrated.
        def track_record_deletions_with_sharding_keys(table_name)
          trigger_name = record_deletion_trigger_name(table_name)
          function_args = [sharding_keys_args(table_name)].compact

          execute(<<~SQL.squish)
            CREATE OR REPLACE TRIGGER #{trigger_name}
            AFTER DELETE ON #{table_name} REFERENCING OLD TABLE AS old_table
            FOR EACH STATEMENT
            EXECUTE FUNCTION #{INSERT_FUNCTION_NAME}(#{function_args.join(', ')});
          SQL
        end

        # TEMPORARY. see track_record_deletions_with_sharding_keys
        def track_record_deletions_override_table_name_with_sharding_keys(table_identifier, parent_table = nil)
          table_name = table_identifier.to_s.split('.').last
          parent_table ||= table_name
          trigger_name = record_deletion_trigger_name(table_name)
          function_args = [connection.quote(parent_table), sharding_keys_args(parent_table)].compact

          execute(<<~SQL.squish)
            CREATE OR REPLACE TRIGGER #{trigger_name}
            AFTER DELETE ON #{table_identifier} REFERENCING OLD TABLE AS old_table
            FOR EACH STATEMENT
            EXECUTE FUNCTION #{INSERT_FUNCTION_NAME_OVERRIDE_TABLE}(#{function_args.join(', ')});
          SQL
        end

        # Resolves the routing targets to pass to the trigger function, one entry per routable
        # sharding key of the table, as
        # [{ table: <deleted-records table>, column: <its sharding key column>, source: <column on
        # the tracked table> }]. Derived from the table's `db/docs` sharding key. Returns an empty
        # array when the table has no sharding key or none of its keys are routable.
        # Raises ArgumentError when two of the table's sharding keys route to the same table.
        def sharding_keys_for(table_name)
          dictionary_entry = Gitlab::Database::Dictionary.entries.find_by_table_name(table_name.to_s)
          return [] unless dictionary_entry&.sharding_key.present?

          targets = dictionary_entry.sharding_key.filter_map do |source_column, referenced_table|
            target = SHARDING_KEY_TARGETS[referenced_table.to_s]
            next unless target

            target.merge(source: source_column.to_s)
          end

          validate_single_target_per_table!(table_name, targets)

          targets
        end

        def sharding_keys_args(table_name)
          targets = sharding_keys_for(table_name)

          return if targets.empty?

          validate_target_tables!(targets)
          validate_sharding_key_columns!(table_name, targets.pluck(:source))

          connection.quote(targets.to_json)
        end

        private

        def record_deletion_trigger_name(table)
          table_name = table.to_s.split('.').last
          "#{table_name}_loose_fk_trigger"
        end

        def record_deletion_trigger_nargs(table)
          connection.select_value(<<~SQL.squish)
            SELECT pg_trigger.tgnargs
            FROM pg_trigger
            WHERE pg_trigger.tgrelid = to_regclass(#{connection.quote(table.to_s)})
              AND pg_trigger.tgname = #{connection.quote(record_deletion_trigger_name(table))}
              AND NOT pg_trigger.tgisinternal
          SQL
        end

        def validate_column_uniqueness!(table, column)
          column_name = column.to_s

          return if connection.primary_keys(table) == [column_name]
          return if connection.index_exists?(table, column_name, unique: true)

          raise ArgumentError, "Column '#{column_name}' on table '#{table}' must have a unique index " \
            "or be the sole primary key. Tracking deletions with a non-unique column can cause accidental data loss."
        end

        def validate_single_target_per_table!(table_name, targets)
          duplicated = targets.map { |target| target[:table] }.tally.select { |_, count| count > 1 }.keys

          return if duplicated.empty?

          raise ArgumentError, "Table '#{table_name}' declares more than one sharding key routed to " \
            "#{duplicated.join(', ')}. Deleted records can only be routed by one of them."
        end

        def validate_target_tables!(targets)
          missing = targets.reject do |target|
            connection.table_exists?(target[:table]) &&
              connection.column_exists?(target[:table], target[:column])
          end

          return if missing.empty?

          identifiers = missing.map { |target| "#{target[:table]}.#{target[:column]}" }

          raise ArgumentError, "Missing loose foreign keys deleted-records target(s) #{identifiers.uniq.join(', ')}."
        end

        # The trigger function reads these columns off the deleted rows, so a stale `db/docs`
        # entry has to fail here instead of on the first DELETE against the table.
        def validate_sharding_key_columns!(table_name, source_columns)
          missing_columns = source_columns - connection.columns(table_name).map(&:name)

          return if missing_columns.empty?

          raise ArgumentError, "Table '#{table_name}' is missing the sharding key column(s) " \
            "#{missing_columns.join(', ')} declared in db/docs."
        end

        def validate_identifier_length!(name)
          return if name.to_s.length <= POSTGRES_IDENTIFIER_LIMIT

          raise ArgumentError, "Identifier '#{name}' is too long " \
            "(#{name.length}/#{POSTGRES_IDENTIFIER_LIMIT} characters)."
        end
      end
    end
  end
end
