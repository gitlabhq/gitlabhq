# frozen_string_literal: true

# Updates the shared loose foreign keys trigger functions so they can route deleted
# records to the sharding-key-specific tables. The functions accept an optional JSONB
# array of routing targets, each entry naming the deleted-records table to write to, its
# sharding key column, and the column to read off the deleted row:
#
#   [{"table": "loose_foreign_keys_project_deleted_records", "column": "project_id", "source": "project_id"}]
#
# The functions hold no mapping of their own, so the routing is defined in one place,
# LooseForeignKeyHelpers::SHARDING_KEY_TARGETS. With no argument (all existing triggers)
# records stay in the cell-local loose_foreign_keys_deleted_records table, so there is no
# behavior change and no trigger is rewritten by this migration.
#
# Every deleted row produces at least one deleted record: one per target it carries a
# sharding key value for, and a cell-local one when it carries none.
# See https://gitlab.com/gitlab-org/gitlab/-/work_items/597949
class UpdateLooseForeignKeysTriggerForShardingKeys < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION insert_into_loose_foreign_keys_deleted_records() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
      DECLARE
        targets JSONB := CASE WHEN TG_NARGS > 0 THEN TG_ARGV[0]::jsonb ELSE '[]'::jsonb END;
        tracked_table_identifier TEXT := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME;
        target_table      TEXT;
        target_column     TEXT;
        source_column     TEXT;
        cell_local_filter TEXT;
      BEGIN
        -- Cell local: no routing targets configured
        IF jsonb_array_length(targets) = 0 THEN
          INSERT INTO loose_foreign_keys_deleted_records
          (fully_qualified_table_name, primary_key_value)
          SELECT tracked_table_identifier, old_table.id
          FROM old_table;

          RETURN NULL;
        END IF;

        -- Route every row to each target it carries a sharding key value for
        FOR target_table, target_column, source_column IN
          SELECT value ->> 'table', value ->> 'column', value ->> 'source'
          FROM jsonb_array_elements(targets)
        LOOP
          EXECUTE format(
            'INSERT INTO %I (fully_qualified_table_name, primary_key_value, %I)
             SELECT $1, old_table.id, old_table.%I
             FROM old_table
             WHERE old_table.%I IS NOT NULL',
             target_table, target_column, source_column, source_column
           )
          USING tracked_table_identifier;
        END LOOP;

        -- Rows carrying no sharding key value at all stay cell local. This filter is the exact
        -- complement of the loop's, so every deleted row lands in one branch or the other
        SELECT string_agg(format('old_table.%I IS NULL', value ->> 'source'), ' AND ')
        INTO cell_local_filter
        FROM jsonb_array_elements(targets);

        EXECUTE format(
          'INSERT INTO loose_foreign_keys_deleted_records
           (fully_qualified_table_name, primary_key_value)
           SELECT $1, old_table.id
           FROM old_table
           WHERE %s',
           cell_local_filter
         )
        USING tracked_table_identifier;

        RETURN NULL;
      END
      $$;
    SQL

    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION insert_into_loose_foreign_keys_deleted_records_override_table() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
      DECLARE
        parent_table_name TEXT := TG_ARGV[0];
        targets JSONB := CASE WHEN TG_NARGS > 1 THEN TG_ARGV[1]::jsonb ELSE '[]'::jsonb END;
        tracked_table_identifier TEXT := current_schema() || '.' || parent_table_name;
        target_table      TEXT;
        target_column     TEXT;
        source_column     TEXT;
        cell_local_filter TEXT;
      BEGIN
        -- Cell local: no routing targets configured
        IF jsonb_array_length(targets) = 0 THEN
          INSERT INTO loose_foreign_keys_deleted_records
          (fully_qualified_table_name, primary_key_value)
          SELECT tracked_table_identifier, old_table.id
          FROM old_table;

          RETURN NULL;
        END IF;

        -- Route every row to each target it carries a sharding key value for
        FOR target_table, target_column, source_column IN
          SELECT value ->> 'table', value ->> 'column', value ->> 'source'
          FROM jsonb_array_elements(targets)
        LOOP
          EXECUTE format(
            'INSERT INTO %I (fully_qualified_table_name, primary_key_value, %I)
             SELECT $1, old_table.id, old_table.%I
             FROM old_table
             WHERE old_table.%I IS NOT NULL',
             target_table, target_column, source_column, source_column
           )
          USING tracked_table_identifier;
        END LOOP;

        -- Rows carrying no sharding key value at all stay cell local. This filter is the exact
        -- complement of the loop's, so every deleted row lands in one branch or the other
        SELECT string_agg(format('old_table.%I IS NULL', value ->> 'source'), ' AND ')
        INTO cell_local_filter
        FROM jsonb_array_elements(targets);

        EXECUTE format(
          'INSERT INTO loose_foreign_keys_deleted_records
           (fully_qualified_table_name, primary_key_value)
           SELECT $1, old_table.id
           FROM old_table
           WHERE %s',
           cell_local_filter
         )
        USING tracked_table_identifier;

        RETURN NULL;
      END
      $$;
    SQL
  end

  def down
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION insert_into_loose_foreign_keys_deleted_records() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
      BEGIN
        INSERT INTO loose_foreign_keys_deleted_records
        (fully_qualified_table_name, primary_key_value)
        SELECT TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME, old_table.id FROM old_table;

        RETURN NULL;
      END
      $$;
    SQL

    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION insert_into_loose_foreign_keys_deleted_records_override_table() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
      BEGIN
        INSERT INTO loose_foreign_keys_deleted_records
        (fully_qualified_table_name, primary_key_value)
        SELECT current_schema() || '.' || TG_ARGV[0], old_table.id FROM old_table;

        RETURN NULL;
      END
      $$;
    SQL
  end
end
