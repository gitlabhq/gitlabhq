# frozen_string_literal: true

class CreateFunctionGitlabSchemaPreventWrite < Gitlab::Database::Migration[2.0]
  TRIGGER_FUNCTION_NAME = 'gitlab_schema_prevent_write'

  enable_lock_retries!

  # This migration is only to make sure that the lock-write trigger function
  # matches what we already have on staging/production for Gitlab.com

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{TRIGGER_FUNCTION_NAME}()
        RETURNS TRIGGER AS
        $$
      BEGIN
          RAISE EXCEPTION 'Table: "%" is write protected within this Gitlab database.', TG_TABLE_NAME
            USING ERRCODE = 'modifying_sql_data_not_permitted',
            HINT = 'Make sure you are using the right database connection';
      END
      $$ LANGUAGE PLPGSQL
    SQL
  end

  def down
    return if Gitlab.com?

    execute(<<~SQL)
      DROP FUNCTION #{TRIGGER_FUNCTION_NAME} CASCADE
    SQL
  end
end
