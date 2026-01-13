# frozen_string_literal: true

class AddShardingKeyTriggerOnGpgKeySubkeys < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  FUNCTION_NAME = 'sync_user_id_from_gpg_keys_table'
  TRIGGER_NAME = 'set_user_id_for_gpg_key_subkeys_on_insert_and_update'

  milestone '18.8'

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{FUNCTION_NAME}()
      RETURNS TRIGGER AS
      $$
      BEGIN
        IF NEW."gpg_key_id" IS NULL OR NEW."user_id" IS NOT NULL THEN
          RETURN NEW;
        END IF;

        SELECT "user_id"
        INTO NEW."user_id"
        FROM "gpg_keys"
        WHERE "id" = NEW."gpg_key_id";

        RETURN NEW;
      END
      $$ LANGUAGE PLPGSQL;
    SQL

    create_trigger(:gpg_key_subkeys, TRIGGER_NAME, FUNCTION_NAME, fires: 'BEFORE INSERT OR UPDATE')
  end

  def down
    drop_trigger(:gpg_key_subkeys, TRIGGER_NAME)

    drop_function(FUNCTION_NAME)
  end
end
