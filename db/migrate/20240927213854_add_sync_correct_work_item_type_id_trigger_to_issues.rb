# frozen_string_literal: true

class AddSyncCorrectWorkItemTypeIdTriggerToIssues < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  include Gitlab::Database::SchemaHelpers

  ISSUES_TABLE = 'issues'
  WORK_ITEM_TYPES_TABLE = 'work_item_types'

  TRIGGER_FUNCTION_NAME = 'update_issue_correct_work_item_type_id_sync_event'
  TRIGGER_NAME = 'trigger_correct_work_item_type_id_sync_event_on_issue_update'

  def up
    create_trigger_function(TRIGGER_FUNCTION_NAME, replace: true) do
      <<~SQL
        SELECT "correct_id"
        INTO NEW."correct_work_item_type_id"
        FROM "#{WORK_ITEM_TYPES_TABLE}"
        WHERE "#{WORK_ITEM_TYPES_TABLE}"."id" = NEW."work_item_type_id";
        RETURN NEW;
      SQL
    end

    create_trigger(
      ISSUES_TABLE, TRIGGER_NAME, TRIGGER_FUNCTION_NAME, fires: 'BEFORE INSERT OR UPDATE of work_item_type_id'
    )
  end

  def down
    drop_trigger(ISSUES_TABLE, TRIGGER_NAME)
    drop_function(TRIGGER_FUNCTION_NAME)
  end
end
