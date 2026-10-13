# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      class SwapColumns
        # `tgenabled` values that `CREATE OR REPLACE TRIGGER` does not preserve, mapped to the
        # clause that restores them. The default, 'O', is what a recreated trigger already has.
        FIRING_MODE_CLAUSES = {
          'D' => 'DISABLE',
          'A' => 'ENABLE ALWAYS',
          'R' => 'ENABLE REPLICA'
        }.freeze

        delegate :quote_table_name, :quote_column_name, :quote, :clear_cache!, :select_all, :say,
          :transaction_open?,
          to: :@migration_context

        def initialize(migration_context:, table:, column1:, column2:)
          @migration_context = migration_context
          @table = table
          @column_name1 = column1
          @column_name2 = column2
        end

        def execute
          verify_runs_in_transaction!

          trigger_definitions = dependent_trigger_definitions
          firing_modes = non_default_firing_modes(trigger_definitions)

          rename_column(@table, @column_name1, :temp_name_for_renaming)
          rename_column(@table, @column_name2, @column_name1)
          rename_column(@table, :temp_name_for_renaming, @column_name2)

          recreate_dependent_triggers(trigger_definitions)
          restore_firing_modes(firing_modes)
        end

        private

        # Renaming a column, recreating a trigger and restoring its firing mode have to commit
        # together, so that no other session observes the table midway through the swap.
        def verify_runs_in_transaction!
          return if transaction_open?

          raise "Cannot swap columns #{@column_name1} and #{@column_name2} on #{@table} outside " \
            "a transaction. Run the swap in a transactional migration, or inside `with_lock_retries` " \
            "if the migration uses `disable_ddl_transaction!`. Note that `DISABLE_LOCK_RETRIES` " \
            "makes `with_lock_retries` run without a transaction."
        end

        # Rails' `rename_column` will rename related indexes
        # using a format e.g. `index_{TABLE_NAME}_on_{KEY1}_and_{KEY2}`
        # This will break the migration if the formated index name is longer than 63 chars, e.g.
        # `index_ci_pipeline_variables_on_pipeline_id_convert_to_bigint_and_key`
        # Therefore, we need to duplicate what Rails has done here without the part renaming related indexes
        def rename_column(table_name, column_name, column2_name)
          clear_cache!
          @migration_context.execute <<~SQL
            ALTER TABLE #{quote_table_name(table_name)}
              RENAME COLUMN #{quote_column_name(column_name)} TO #{quote_column_name(column2_name)}
          SQL
        end

        # Triggers reference columns by attribute number, in an `UPDATE OF` list or a `WHEN`
        # clause, so a rename leaves them bound to the old column. Captured before the renames
        # so the definitions still name the columns the application refers to.
        # See doc/development/database/avoiding_downtime_in_migrations.md.
        def dependent_trigger_definitions
          rows = select_all(<<~SQL)
            SELECT t.oid,
                   t.tgname AS name,
                   pg_get_triggerdef(t.oid) AS definition,
                   (t.tgconstraint <> 0) AS constraint_trigger
            FROM pg_trigger t
            WHERE t.tgrelid = #{quote(@table.to_s)}::regclass
              AND NOT t.tgisinternal
              AND EXISTS (
                SELECT 1
                FROM pg_depend d
                JOIN pg_attribute a ON a.attrelid = d.refobjid AND a.attnum = d.refobjsubid
                WHERE d.classid = 'pg_trigger'::regclass
                  AND d.objid = t.oid
                  AND d.refobjsubid > 0
                  AND a.attname IN (#{quote(@column_name1.to_s)}, #{quote(@column_name2.to_s)})
              )
            ORDER BY t.tgname
          SQL

          rows.to_a.tap { |definitions| verify_triggers_can_be_recreated!(definitions) }
        end

        # PostgreSQL rejects `CREATE OR REPLACE TRIGGER` for constraint triggers, so fail before
        # renaming rather than leaving one bound to the wrong column.
        def verify_triggers_can_be_recreated!(definitions)
          names = definitions.select { |row| row['constraint_trigger'] }.pluck('name')
          return if names.empty?

          raise "Cannot swap columns #{@column_name1} and #{@column_name2} on #{@table}: " \
            "constraint trigger(s) #{names.join(', ')} depend on these columns and PostgreSQL " \
            "cannot replace a constraint trigger. Drop and recreate the trigger(s) around the swap."
        end

        # Recreating a trigger resets its firing mode, and `pg_get_triggerdef` does not render the
        # mode, so the modes are captured here and reapplied after the replay. A clone's parent is
        # the clone one level up, hence the recursion for sub-partitions.
        def non_default_firing_modes(definitions)
          return [] if definitions.empty?

          oids = definitions.pluck('oid').join(', ')

          select_all(<<~SQL).to_a
            WITH RECURSIVE trigger_and_clones AS (
              SELECT oid, tgrelid, tgname, tgenabled
              FROM pg_trigger
              WHERE oid IN (#{oids})
              UNION ALL
              SELECT c.oid, c.tgrelid, c.tgname, c.tgenabled
              FROM pg_trigger c
              JOIN trigger_and_clones p ON c.tgparentid = p.oid
            )
            SELECT tgrelid::regclass::text AS table_name,
                   tgname AS name,
                   tgenabled AS firing_mode
            FROM trigger_and_clones
            WHERE tgenabled <> 'O'
            ORDER BY table_name, name
          SQL
        end

        # `ONLY` keeps each statement to the relation it names, so a mode set on one partition is
        # not overwritten by the recursion from its parent.
        def restore_firing_modes(firing_modes)
          firing_modes.each do |row|
            clause = FIRING_MODE_CLAUSES.fetch(row['firing_mode'])

            @migration_context.execute(<<~SQL)
              ALTER TABLE ONLY #{quote_table_name(row['table_name'])}
                #{clause} TRIGGER #{quote_column_name(row['name'])}
            SQL

            say "Restored #{clause} on trigger #{row['name']} on #{row['table_name']}"
          end
        end

        def recreate_dependent_triggers(definitions)
          definitions.each do |row|
            statement = row['definition'].sub(/\ACREATE TRIGGER\b/, 'CREATE OR REPLACE TRIGGER')

            @migration_context.execute(statement)

            say "Recreated trigger #{row['name']} on #{@table} so it refers to the swapped columns"
          end
        end
      end
    end
  end
end
