# frozen_string_literal: true

class AddListsEnsureShardingKeyTrigger < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::SchemaHelpers

  milestone '17.11'

  LISTS_TABLE = 'lists'

  TRIGGER_FUNCTION_NAME = 'ensure_lists_sharding_key'
  TRIGGER_NAME = 'trigger_ensure_lists_sharding_key'

  def up
    create_trigger_function(TRIGGER_FUNCTION_NAME, replace: true) do
      <<~SQL
        IF NEW."project_id" IS NULL AND NEW."group_id" IS NULL THEN
          SELECT "boards"."project_id", "boards"."group_id"
          INTO NEW."project_id", NEW."group_id"
          FROM "boards"
          WHERE "boards"."id" = NEW."board_id";
        END IF;
        RETURN NEW;
      SQL
    end

    create_trigger(
      LISTS_TABLE, TRIGGER_NAME, TRIGGER_FUNCTION_NAME, fires: 'BEFORE INSERT OR UPDATE'
    )
  end

  def down
    drop_trigger(LISTS_TABLE, TRIGGER_NAME)
    drop_function(TRIGGER_FUNCTION_NAME)
  end
end
