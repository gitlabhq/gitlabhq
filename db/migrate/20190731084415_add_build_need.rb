# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddBuildNeed < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_build_needs, id: :serial do |t|
      t.integer :build_id, null: false
      t.text :name, null: false # rubocop:disable Migration/AddLimitToTextColumns

      t.index [:build_id, :name], unique: true
      t.foreign_key :ci_builds, column: :build_id, on_delete: :cascade
    end
  end
end
