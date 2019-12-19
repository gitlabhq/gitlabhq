# frozen_string_literal: true

class AddCiResourceGroups < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :ci_resource_groups do |t|
      t.timestamps_with_timezone
      t.bigint :project_id, null: false
      t.string :key, null: false, limit: 255
      t.index %i[project_id key], unique: true
    end

    create_table :ci_resources do |t|
      t.timestamps_with_timezone
      t.references :resource_group, null: false, index: false, foreign_key: { to_table: :ci_resource_groups, on_delete: :cascade }
      t.bigint :build_id, null: true
      t.index %i[build_id]
      t.index %i[resource_group_id build_id], unique: true
    end
  end
end
