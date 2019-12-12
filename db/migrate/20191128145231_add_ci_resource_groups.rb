# frozen_string_literal: true

class AddCiResourceGroups < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :ci_resource_groups do |t|
      t.timestamps_with_timezone
      t.references :project, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.string :key, null: false, limit: 255
      t.index %i[project_id key], unique: true
    end

    create_table :ci_resources do |t|
      t.timestamps_with_timezone
      t.references :resource_group, null: false, index: false, foreign_key: { to_table: :ci_resource_groups, on_delete: :cascade }
      t.references :build, null: true, index: true, foreign_key: { to_table: :ci_builds, on_delete: :nullify }
      t.index %i[resource_group_id build_id], unique: true
    end

    add_column :ci_builds, :resource_group_id, :bigint
    add_column :ci_builds, :waiting_for_resource_at, :datetime_with_timezone
  end
end
