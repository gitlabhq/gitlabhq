# frozen_string_literal: true

class CreateProjectsSyncTrigger < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::SchemaHelpers

  enable_lock_retries!

  TABLE_NAME = 'projects'
  EVENT_TABLE_NAME = 'projects_sync_events'
  FUNCTION_NAME = 'insert_projects_sync_event'
  TRIGGER_ON_INSERT = 'trigger_projects_parent_id_on_insert'
  TRIGGER_ON_UPDATE = 'trigger_projects_parent_id_on_update'

  def up
    create_trigger_function(FUNCTION_NAME) do
      <<~SQL
        INSERT INTO #{EVENT_TABLE_NAME} (project_id)
        VALUES(COALESCE(NEW.id, OLD.id));
        RETURN NULL;
      SQL
    end

    create_trigger(TABLE_NAME, TRIGGER_ON_INSERT, FUNCTION_NAME, fires: 'AFTER INSERT')

    create_trigger(TABLE_NAME, TRIGGER_ON_UPDATE, FUNCTION_NAME, fires: 'AFTER UPDATE') do
      <<~SQL
        WHEN (OLD.namespace_id IS DISTINCT FROM NEW.namespace_id)
      SQL
    end
  end

  def down
    drop_trigger(TABLE_NAME, TRIGGER_ON_INSERT)
    drop_trigger(TABLE_NAME, TRIGGER_ON_UPDATE)
    drop_function(FUNCTION_NAME)
  end
end
