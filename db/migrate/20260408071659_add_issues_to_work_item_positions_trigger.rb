# frozen_string_literal: true

class AddIssuesToWorkItemPositionsTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  include Gitlab::Database::SchemaHelpers

  SOURCE_TABLE_NAME = :issues
  TRIGGER_FUNCTION_NAME = 'sync_work_item_positions_from_issues'
  TRIGGER_NAME = "trigger_#{TRIGGER_FUNCTION_NAME}"

  def up
    create_trigger_function(TRIGGER_FUNCTION_NAME, replace: true) do
      <<~SQL
        INSERT INTO work_item_positions (
          work_item_id,
          namespace_id,
          relative_position,
          created_at,
          updated_at
        )
        VALUES (
          NEW.id,
          NEW.namespace_id,
          NEW.relative_position,
          NOW(),
          NOW()
        )
        ON CONFLICT (work_item_id)
        DO UPDATE SET
          relative_position = EXCLUDED.relative_position,
          namespace_id = EXCLUDED.namespace_id,
          updated_at = NOW();
        RETURN NULL;
      SQL
    end

    create_trigger(
      SOURCE_TABLE_NAME,
      TRIGGER_NAME,
      TRIGGER_FUNCTION_NAME,
      fires: "AFTER INSERT OR UPDATE OF relative_position, namespace_id",
      replace: true
    )
  end

  def down
    drop_trigger(SOURCE_TABLE_NAME, TRIGGER_NAME)
    drop_function(TRIGGER_FUNCTION_NAME)
  end
end
