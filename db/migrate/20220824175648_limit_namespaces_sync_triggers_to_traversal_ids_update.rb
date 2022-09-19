# frozen_string_literal: true

class LimitNamespacesSyncTriggersToTraversalIdsUpdate < Gitlab::Database::Migration[2.0]
  include Gitlab::Database::SchemaHelpers

  enable_lock_retries!

  TABLE_NAME = 'namespaces'
  EVENT_TABLE_NAME = 'namespaces_sync_events'
  FUNCTION_NAME = 'insert_namespaces_sync_event'
  OLD_TRIGGER_ON_INSERT = 'trigger_namespaces_parent_id_on_insert'
  OLD_TRIGGER_ON_UPDATE = 'trigger_namespaces_parent_id_on_update'
  NEW_TRIGGER_ON_UPDATE = 'trigger_namespaces_traversal_ids_on_update'

  def up
    create_trigger(TABLE_NAME, NEW_TRIGGER_ON_UPDATE, FUNCTION_NAME, fires: 'AFTER UPDATE') do
      <<~SQL
        WHEN (OLD.traversal_ids IS DISTINCT FROM NEW.traversal_ids)
      SQL
    end
    drop_trigger(TABLE_NAME, OLD_TRIGGER_ON_UPDATE)
    drop_trigger(TABLE_NAME, OLD_TRIGGER_ON_INSERT)
  end

  # Revert both triggers to the version defined in db/migrate/20211011141242_create_namespaces_sync_trigger.rb
  def down
    create_trigger(TABLE_NAME, OLD_TRIGGER_ON_INSERT, FUNCTION_NAME, fires: 'AFTER INSERT')
    create_trigger(TABLE_NAME, OLD_TRIGGER_ON_UPDATE, FUNCTION_NAME, fires: 'AFTER UPDATE') do
      <<~SQL
        WHEN (OLD.parent_id IS DISTINCT FROM NEW.parent_id)
      SQL
    end
    drop_trigger(TABLE_NAME, NEW_TRIGGER_ON_UPDATE)
  end
end
