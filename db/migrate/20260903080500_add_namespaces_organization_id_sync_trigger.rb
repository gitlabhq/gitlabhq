# frozen_string_literal: true

class AddNamespacesOrganizationIdSyncTrigger < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  include Gitlab::Database::SchemaHelpers

  TABLE_NAME = :namespaces
  TRIGGER_NAME = 'trigger_namespaces_organization_id_on_update'
  FUNCTION_NAME = 'insert_namespaces_sync_event'

  def up
    create_trigger(TABLE_NAME, TRIGGER_NAME, FUNCTION_NAME, fires: 'AFTER UPDATE', replace: true) do
      'WHEN (OLD.organization_id IS DISTINCT FROM NEW.organization_id)'
    end
  end

  def down
    drop_trigger(TABLE_NAME, TRIGGER_NAME)
  end
end
