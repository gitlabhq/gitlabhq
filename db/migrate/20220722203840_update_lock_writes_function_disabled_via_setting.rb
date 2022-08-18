# frozen_string_literal: true

class UpdateLockWritesFunctionDisabledViaSetting < Gitlab::Database::Migration[2.0]
  TRIGGER_FUNCTION_NAME = 'gitlab_schema_prevent_write'

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{TRIGGER_FUNCTION_NAME}()
        RETURNS TRIGGER AS
        $$
      BEGIN
          IF COALESCE(NULLIF(current_setting(CONCAT('lock_writes.', TG_TABLE_NAME), true), ''), 'true') THEN
            RAISE EXCEPTION 'Table: "%" is write protected within this Gitlab database.', TG_TABLE_NAME
              USING ERRCODE = 'modifying_sql_data_not_permitted',
              HINT = 'Make sure you are using the right database connection';
          END IF;
          RETURN NEW;
      END
      $$ LANGUAGE PLPGSQL;
    SQL
  end

  def down
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
end
