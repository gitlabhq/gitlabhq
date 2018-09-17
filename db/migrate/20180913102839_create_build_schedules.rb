# frozen_string_literal: true

class CreateBuildSchedules < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    create_table :ci_build_schedules, id: :bigserial do |t|
      t.integer :build_id, null: false
      t.datetime :execute_at, null: false

      t.foreign_key :ci_builds, column: :build_id, on_delete: :cascade
      t.index :build_id, unique: true
    end
  end
end
