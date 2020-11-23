# frozen_string_literal: true

class CreateIncidentManagementOncallSchedules < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      unless table_exists?(:incident_management_oncall_schedules)
        create_table :incident_management_oncall_schedules do |t|
          t.timestamps_with_timezone
          t.references :project, index: true, null: false, foreign_key: { on_delete: :cascade }
          t.integer :iid, null: false
          t.text :name, null: false
          t.text :description
          t.text :timezone

          t.index %w(project_id iid), name: 'index_im_oncall_schedules_on_project_id_and_iid', unique: true, using: :btree
        end
      end
    end

    add_text_limit :incident_management_oncall_schedules, :name, 200
    add_text_limit :incident_management_oncall_schedules, :description, 1000
    add_text_limit :incident_management_oncall_schedules, :timezone, 100
  end

  def down
    with_lock_retries do
      drop_table :incident_management_oncall_schedules
    end
  end
end
