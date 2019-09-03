# frozen_string_literal: true

class CreateMilestoneReleasesTable < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_table :milestone_releases do |t|
      t.references :milestone, foreign_key: { on_delete: :cascade }, null: false, index: false
      t.references :release, foreign_key: { on_delete: :cascade }, null: false
    end

    add_index :milestone_releases, [:milestone_id, :release_id], unique: true, name: 'index_miletone_releases_on_milestone_and_release'
  end

  def down
    drop_table :milestone_releases
  end
end
