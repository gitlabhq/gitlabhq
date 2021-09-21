# frozen_string_literal: true

class AddFunctionForInsertingDeletedRecords < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{DELETED_RECORDS_INSERT_FUNCTION_NAME}()
      RETURNS TRIGGER AS
      $$
      BEGIN
        INSERT INTO loose_foreign_keys_deleted_records
        (deleted_table_name, deleted_table_primary_key_value)
        SELECT TG_TABLE_NAME, old_table.id FROM old_table
        ON CONFLICT DO NOTHING;

        RETURN NULL;
      END
      $$ LANGUAGE PLPGSQL
    SQL
  end

  def down
    drop_function(DELETED_RECORDS_INSERT_FUNCTION_NAME)
  end
end
