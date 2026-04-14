# frozen_string_literal: true

class AddWorkItemTypeIdTriggerToWorkItemTypeVisibilities < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  milestone '18.11'

  # Trigger function introduced in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223997
  TRIGGER_FUNCTION = 'validate_work_item_type_id_is_valid'
  FIRES = 'BEFORE INSERT OR UPDATE OF work_item_type_id'
  TRIGGER_NAME = 'validate_work_item_type_on_insert_or_update_type_visibilities'

  def up
    create_trigger(:work_item_type_visibilities, TRIGGER_NAME, TRIGGER_FUNCTION, fires: FIRES, replace: true)
  end

  def down
    drop_trigger(:work_item_type_visibilities, TRIGGER_NAME)
  end
end
