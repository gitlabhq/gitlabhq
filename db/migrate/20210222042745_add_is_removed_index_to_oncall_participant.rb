# frozen_string_literal: true

class AddIsRemovedIndexToOncallParticipant < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false
  EXISTING_INDEX_NAME = 'index_inc_mgmnt_oncall_participants_on_oncall_rotation_id'
  NEW_INDEX_NAME = 'index_inc_mgmnt_oncall_pcpnt_on_oncall_rotation_id_is_removed'

  def up
    add_concurrent_index :incident_management_oncall_participants, [:oncall_rotation_id, :is_removed], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name(:incident_management_oncall_participants, EXISTING_INDEX_NAME)
  end

  def down
    add_concurrent_index :incident_management_oncall_participants, :oncall_rotation_id, name: EXISTING_INDEX_NAME
    remove_concurrent_index_by_name(:incident_management_oncall_participants, NEW_INDEX_NAME)
  end
end
