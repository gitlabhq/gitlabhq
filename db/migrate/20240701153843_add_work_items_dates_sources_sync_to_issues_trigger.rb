# frozen_string_literal: true

class AddWorkItemsDatesSourcesSyncToIssuesTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  include Gitlab::Database::SchemaHelpers

  enable_lock_retries!

  WORK_ITEM_DATES_SOURCE_TABLE_NAME = 'work_item_dates_sources'

  TRIGGER_FUNCTION_NAME = 'sync_issues_dates_with_work_item_dates_sources'
  TRIGGER_NAME = "trigger_#{TRIGGER_FUNCTION_NAME}"

  def up
    create_trigger_function(TRIGGER_FUNCTION_NAME, replace: true) do
      <<~SQL
        UPDATE
          issues
        SET
          start_date = NEW.start_date,
          due_date = NEW.due_date
        WHERE
          issues.id = NEW.issue_id;

        RETURN NULL;
      SQL
    end

    create_trigger(
      WORK_ITEM_DATES_SOURCE_TABLE_NAME,
      TRIGGER_NAME,
      TRIGGER_FUNCTION_NAME,
      fires: "AFTER INSERT OR UPDATE OF start_date, due_date"
    )
  end

  def down
    drop_trigger(WORK_ITEM_DATES_SOURCE_TABLE_NAME, TRIGGER_NAME)
    drop_function(TRIGGER_FUNCTION_NAME)
  end
end
