# frozen_string_literal: true

class CreateDastProfileSchedule < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_dast_profile_schedules_active_next_run_at'

  def up
    table_comment = {
      owner: 'group::dynamic analysis', description: 'Scheduling for scans using DAST Profiles'
    }

    create_table_with_constraints :dast_profile_schedules, comment: table_comment.to_json do |t|
      t.bigint :project_id, null: false
      t.bigint :dast_profile_id, null: false
      t.bigint :user_id

      t.datetime_with_timezone :next_run_at, null: false
      t.timestamps_with_timezone null: false
      t.boolean :active, default: true, null: false
      t.text :cron, null: false
      t.text_limit :cron, 255

      t.index %i[active next_run_at], name: INDEX_NAME
      t.index %i[project_id dast_profile_id], unique: true
      t.index :dast_profile_id
      t.index :user_id
    end
  end

  def down
    with_lock_retries do
      drop_table :dast_profile_schedules
    end
  end
end
