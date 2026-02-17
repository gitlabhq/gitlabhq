# frozen_string_literal: true

class AddShardingKeyTriggerToWebHookLogsDaily < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  milestone '18.9'

  TABLE_NAME = :web_hook_logs_daily
  PARENT_TABLE = :web_hooks
  FOREIGN_KEY = :web_hook_id
  TRIGGER_NAME = 'trigger_web_hook_logs_daily_assign_sharding_keys'

  def up
    create_trigger_function(TRIGGER_NAME) do
      <<~SQL
        IF num_nonnulls(NEW.organization_id, NEW.project_id, NEW.group_id) <> 1 THEN
          SELECT organization_id, project_id, group_id
          INTO NEW.organization_id, NEW.project_id, NEW.group_id
          FROM web_hooks
          WHERE web_hooks.id = NEW.web_hook_id;
        END IF;

        RETURN NEW;
      SQL
    end

    create_trigger(TABLE_NAME, TRIGGER_NAME, TRIGGER_NAME, fires: 'BEFORE INSERT OR UPDATE')
  end

  def down
    drop_trigger(TABLE_NAME, TRIGGER_NAME)
    drop_function(TRIGGER_NAME)
  end
end
