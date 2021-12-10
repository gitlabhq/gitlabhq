# frozen_string_literal: true

class CreateNamespacesSyncTrigger < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::SchemaHelpers

  enable_lock_retries!

  TABLE_NAME = 'namespaces'
  EVENT_TABLE_NAME = 'namespaces_sync_events'
  FUNCTION_NAME = 'insert_namespaces_sync_event'
  TRIGGER_ON_INSERT = 'trigger_namespaces_parent_id_on_insert'
  TRIGGER_ON_UPDATE = 'trigger_namespaces_parent_id_on_update'

  def up
    create_trigger_function(FUNCTION_NAME) do
      <<~SQL
        INSERT INTO #{EVENT_TABLE_NAME} (namespace_id)
        VALUES(COALESCE(NEW.id, OLD.id));
        RETURN NULL;
      SQL
    end

    create_trigger(TABLE_NAME, TRIGGER_ON_INSERT, FUNCTION_NAME, fires: 'AFTER INSERT')

    create_trigger(TABLE_NAME, TRIGGER_ON_UPDATE, FUNCTION_NAME, fires: 'AFTER UPDATE') do
      <<~SQL
        WHEN (OLD.parent_id IS DISTINCT FROM NEW.parent_id)
      SQL
    end
  end

  def down
    drop_trigger(TABLE_NAME, TRIGGER_ON_INSERT)
    drop_trigger(TABLE_NAME, TRIGGER_ON_UPDATE)
    drop_function(FUNCTION_NAME)
  end
end
