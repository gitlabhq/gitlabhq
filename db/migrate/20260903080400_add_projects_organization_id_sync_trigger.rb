# frozen_string_literal: true

class AddProjectsOrganizationIdSyncTrigger < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  include Gitlab::Database::SchemaHelpers

  TABLE_NAME = :projects
  TRIGGER_NAME = 'trigger_projects_organization_id_on_update'
  FUNCTION_NAME = 'insert_projects_sync_event'

  def up
    create_trigger(TABLE_NAME, TRIGGER_NAME, FUNCTION_NAME, fires: 'AFTER UPDATE', replace: true) do
      'WHEN (OLD.organization_id IS DISTINCT FROM NEW.organization_id)'
    end
  end

  def down
    drop_trigger(TABLE_NAME, TRIGGER_NAME)
  end
end
