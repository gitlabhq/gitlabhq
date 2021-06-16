# frozen_string_literal: true

class AddRunningBuildsTable < ActiveRecord::Migration[6.0]
  def up
    create_table :ci_running_builds do |t|
      t.references :build, index: { unique: true }, null: false, foreign_key: { to_table: :ci_builds, on_delete: :cascade }
      t.references :project, index: true, null: false, foreign_key: { on_delete: :cascade }
      t.references :runner, index: true, null: false, foreign_key: { to_table: :ci_runners, on_delete: :cascade }
      t.datetime_with_timezone :created_at, null: false, default: -> { 'NOW()' }
      t.integer :runner_type, limit: 2, null: false
    end
  end

  def down
    drop_table :ci_running_builds
  end
end
