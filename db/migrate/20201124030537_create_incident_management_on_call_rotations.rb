# frozen_string_literal: true

class CreateIncidentManagementOnCallRotations < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:incident_management_oncall_rotations)
      with_lock_retries do
        create_table :incident_management_oncall_rotations do |t|
          t.timestamps_with_timezone
          t.references :oncall_schedule, index: false, null: false, foreign_key: { to_table: :incident_management_oncall_schedules, on_delete: :cascade }
          t.integer :length, null: false
          t.integer :length_unit, limit: 2, null: false
          t.datetime_with_timezone :starts_at, null: false
          t.text :name, null: false

          t.index %w(oncall_schedule_id id), name: 'index_inc_mgmnt_oncall_rotations_on_oncall_schedule_id_and_id', unique: true, using: :btree
          t.index %w(oncall_schedule_id name), name: 'index_inc_mgmnt_oncall_rotations_on_oncall_schedule_id_and_name', unique: true, using: :btree
        end
      end
    end

    add_text_limit :incident_management_oncall_rotations, :name, 200
  end

  def down
    with_lock_retries do
      drop_table :incident_management_oncall_rotations
    end
  end
end
