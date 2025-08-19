# frozen_string_literal: true

class AddJiraTrackerDataShardingKeyTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  include Gitlab::Database::SchemaHelpers

  TRACKER_TABLE = 'jira_tracker_data'
  INTEGRATIONS_TABLE = 'integrations'

  TRIGGER_FUNCTION_NAME = 'update_jira_tracker_data_sharding_key'
  TRIGGER_NAME = 'trigger_jira_tracker_data_sharding_key_on_insert'

  def up
    create_trigger_function(TRIGGER_FUNCTION_NAME, replace: true) do
      <<~SQL
        SELECT
          "#{INTEGRATIONS_TABLE}"."project_id",
          "#{INTEGRATIONS_TABLE}"."group_id",
          "#{INTEGRATIONS_TABLE}"."organization_id"
        INTO
          NEW."project_id",
          NEW."group_id",
          NEW."organization_id"
        FROM "#{INTEGRATIONS_TABLE}"
        WHERE "#{INTEGRATIONS_TABLE}"."id" = NEW."integration_id";
        RETURN NEW;
      SQL
    end

    create_trigger(TRACKER_TABLE, TRIGGER_NAME, TRIGGER_FUNCTION_NAME, fires: 'BEFORE INSERT') do
      'WHEN (NEW."project_id" IS NULL AND NEW."group_id" IS NULL AND NEW."organization_id" IS NULL)'
    end
  end

  def down
    drop_trigger(TRACKER_TABLE, TRIGGER_NAME)
    drop_function(TRIGGER_FUNCTION_NAME)
  end
end
