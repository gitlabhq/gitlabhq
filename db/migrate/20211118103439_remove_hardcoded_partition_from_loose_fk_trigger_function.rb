# frozen_string_literal: true

class RemoveHardcodedPartitionFromLooseFkTriggerFunction < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  enable_lock_retries!

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{DELETED_RECORDS_INSERT_FUNCTION_NAME}()
      RETURNS TRIGGER AS
      $$
      BEGIN
        INSERT INTO loose_foreign_keys_deleted_records
        (fully_qualified_table_name, primary_key_value)
        SELECT TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME, old_table.id FROM old_table;

        RETURN NULL;
      END
      $$ LANGUAGE PLPGSQL
    SQL
  end

  def down
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{DELETED_RECORDS_INSERT_FUNCTION_NAME}()
      RETURNS TRIGGER AS
      $$
      BEGIN
        INSERT INTO loose_foreign_keys_deleted_records
        (partition, fully_qualified_table_name, primary_key_value)
        SELECT 1, TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME, old_table.id FROM old_table
        ON CONFLICT DO NOTHING;

        RETURN NULL;
      END
      $$ LANGUAGE PLPGSQL
    SQL
  end
end
