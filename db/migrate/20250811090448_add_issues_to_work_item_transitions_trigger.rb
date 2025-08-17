# frozen_string_literal: true

class AddIssuesToWorkItemTransitionsTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  include Gitlab::Database::SchemaHelpers

  SOURCE_TABLE_NAME = 'issues'
  TRIGGER_FUNCTION_NAME = 'sync_work_item_transitions_from_issues'
  TRIGGER_NAME = "trigger_#{TRIGGER_FUNCTION_NAME}"

  def up
    create_trigger_function(TRIGGER_FUNCTION_NAME, replace: true) do
      <<~SQL
        INSERT INTO work_item_transitions (
          work_item_id,
          namespace_id,
          moved_to_id,
          duplicated_to_id,
          promoted_to_epic_id
        )
        VALUES (
          NEW.id,
          NEW.namespace_id,
          NEW.moved_to_id,
          NEW.duplicated_to_id,
          NEW.promoted_to_epic_id
        )
        ON CONFLICT (work_item_id)
        DO UPDATE SET
          moved_to_id = EXCLUDED.moved_to_id,
          duplicated_to_id = EXCLUDED.duplicated_to_id,
          promoted_to_epic_id = EXCLUDED.promoted_to_epic_id,
          namespace_id = EXCLUDED.namespace_id;
        RETURN NULL;
      SQL
    end

    create_trigger(
      SOURCE_TABLE_NAME,
      TRIGGER_NAME,
      TRIGGER_FUNCTION_NAME,
      fires: "AFTER INSERT OR UPDATE OF moved_to_id, duplicated_to_id, promoted_to_epic_id, namespace_id"
    )
  end

  def down
    drop_trigger(SOURCE_TABLE_NAME, TRIGGER_NAME)
    drop_function(TRIGGER_FUNCTION_NAME)
  end
end
