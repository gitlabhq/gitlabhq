# frozen_string_literal: true

class AddIncidentManagementOnCallParticipants < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  PARTICIPANT_ROTATION_INDEX_NAME = 'index_inc_mgmnt_oncall_participants_on_oncall_rotation_id'
  PARTICIPANT_USER_INDEX_NAME = 'index_inc_mgmnt_oncall_participants_on_oncall_user_id'
  UNIQUE_INDEX_NAME = 'index_inc_mgmnt_oncall_participants_on_user_id_and_rotation_id'

  disable_ddl_transaction!

  def up
    unless table_exists?(:incident_management_oncall_participants)
      with_lock_retries do
        create_table :incident_management_oncall_participants do |t|
          t.references :oncall_rotation, index: false, null: false, foreign_key: { to_table: :incident_management_oncall_rotations, on_delete: :cascade }
          t.references :user, index: false, null: false, foreign_key: { on_delete: :cascade }
          t.integer :color_palette, limit: 2, null: false
          t.integer :color_weight, limit: 2, null: false
          t.index :user_id, name: PARTICIPANT_USER_INDEX_NAME
          t.index :oncall_rotation_id, name: PARTICIPANT_ROTATION_INDEX_NAME
          t.index [:user_id, :oncall_rotation_id], unique: true, name: UNIQUE_INDEX_NAME
        end
      end
    end
  end

  def down
    drop_table :incident_management_oncall_participants
  end
end
