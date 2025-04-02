# frozen_string_literal: true

class DropIssuesWorkItemTypeIdSyncTrigger < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::SchemaHelpers

  milestone '17.11'

  ISSUES_TABLE = 'issues'
  WORK_ITEM_TYPES_TABLE = 'work_item_types'
  TRIGGER_FUNCTION_NAME = 'sync_issues_correct_work_item_type_id_bidirectional'
  TRIGGER_NAME = 'trigger_issues_work_item_type_id_bidirectional_sync'

  def up
    drop_trigger(ISSUES_TABLE, TRIGGER_NAME)
    drop_function(TRIGGER_FUNCTION_NAME)
  end

  def down
    create_trigger_function(TRIGGER_FUNCTION_NAME, replace: true) do
      <<~SQL
        if NEW."work_item_type_id" IS NOT NULL
        AND (
          NEW."correct_work_item_type_id" = OLD."correct_work_item_type_id"
          OR (OLD."correct_work_item_type_id" IS NULL AND NEW."correct_work_item_type_id" IS NULL)
        ) then
        SELECT
          "correct_id" INTO NEW."correct_work_item_type_id"
        FROM
          "#{WORK_ITEM_TYPES_TABLE}"
        WHERE
          "#{WORK_ITEM_TYPES_TABLE}"."id" = NEW."work_item_type_id";
        end if;

        if NEW."correct_work_item_type_id" IS NOT NULL
        AND (
          NEW."work_item_type_id" = OLD."work_item_type_id"
          OR (OLD."work_item_type_id" IS NULL AND NEW."work_item_type_id" IS NULL)
        ) then
        SELECT
          "id" INTO NEW."work_item_type_id"
        FROM
          "#{WORK_ITEM_TYPES_TABLE}"
        WHERE
          "#{WORK_ITEM_TYPES_TABLE}"."correct_id" = NEW."correct_work_item_type_id";
        end if;

        RETURN NEW;
      SQL
    end

    create_trigger(
      ISSUES_TABLE,
      TRIGGER_NAME,
      TRIGGER_FUNCTION_NAME,
      fires: 'BEFORE INSERT OR UPDATE of work_item_type_id, correct_work_item_type_id'
    )
  end
end
