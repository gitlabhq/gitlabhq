# frozen_string_literal: true

class AddCatalogResourceSyncEventTriggers < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  include Gitlab::Database::SchemaHelpers

  enable_lock_retries!

  EVENTS_TABLE_NAME = 'p_catalog_resource_sync_events'
  RESOURCES_TABLE_NAME = 'catalog_resources'
  PROJECTS_TABLE_NAME = 'projects'

  TRIGGER_FUNCTION_NAME = 'insert_catalog_resource_sync_event'
  TRIGGER_NAME = 'trigger_catalog_resource_sync_event_on_project_update'

  def up
    create_trigger_function(TRIGGER_FUNCTION_NAME, replace: true) do
      <<~SQL
        INSERT INTO #{EVENTS_TABLE_NAME} (catalog_resource_id, project_id)
        SELECT id, OLD.id FROM #{RESOURCES_TABLE_NAME}
        WHERE project_id = OLD.id;
        RETURN NULL;
      SQL
    end

    create_trigger(
      PROJECTS_TABLE_NAME, TRIGGER_NAME, TRIGGER_FUNCTION_NAME, fires: 'AFTER UPDATE'
    ) do
      <<~SQL
        WHEN (
          OLD.name IS DISTINCT FROM NEW.name OR
          OLD.description IS DISTINCT FROM NEW.description OR
          OLD.visibility_level IS DISTINCT FROM NEW.visibility_level
        )
      SQL
    end
  end

  def down
    drop_trigger(PROJECTS_TABLE_NAME, TRIGGER_NAME)
    drop_function(TRIGGER_FUNCTION_NAME)
  end
end
