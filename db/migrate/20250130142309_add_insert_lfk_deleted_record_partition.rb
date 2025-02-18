# frozen_string_literal: true

class AddInsertLfkDeletedRecordPartition < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  # TG_ARGV[0] is the table name. It should always be on the default schema (public)
  def up
    connection.execute(
      <<~SQL
        CREATE FUNCTION #{function_name}() RETURNS trigger
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
    )
  end

  def down
    connection.execute("DROP FUNCTION #{function_name} CASCADE")
  end

  def function_name
    Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers::INSERT_FUNCTION_NAME_OVERRIDE_TABLE
  end
end
