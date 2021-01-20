# frozen_string_literal: true

class CreateIncidentManagementOncallShifts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    unless table_exists?(:incident_management_oncall_shifts)
      with_lock_retries do
        create_table :incident_management_oncall_shifts do |t|
          t.references :rotation, null: false, foreign_key: { to_table: :incident_management_oncall_rotations, on_delete: :cascade }
          t.references :participant, null: false, foreign_key: { to_table: :incident_management_oncall_participants, on_delete: :cascade }
          t.datetime_with_timezone :starts_at, null: false
          t.datetime_with_timezone :ends_at, null: false
        end

        execute <<~SQL
          ALTER TABLE incident_management_oncall_shifts
            ADD CONSTRAINT inc_mgmnt_no_overlapping_oncall_shifts
            EXCLUDE USING gist
            ( rotation_id WITH =,
              tstzrange(starts_at, ends_at, '[)') WITH &&
            )
        SQL
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :incident_management_oncall_shifts
    end
  end
end
