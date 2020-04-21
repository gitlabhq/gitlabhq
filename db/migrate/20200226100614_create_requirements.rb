# frozen_string_literal: true

class CreateRequirements < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :requirements do |t|
      t.timestamps_with_timezone null: false
      t.integer :project_id, null: false
      t.integer :author_id
      t.integer :iid, null: false
      t.integer :cached_markdown_version
      t.integer :state, limit: 2, default: 1, null: false
      t.string :title, limit: 255, null: false
      t.text :title_html # rubocop:disable Migration/AddLimitToTextColumns

      t.index :project_id
      t.index :author_id
      t.index :title, name: "index_requirements_on_title_trigram", using: :gin, opclass: :gin_trgm_ops
      t.index :state
      t.index :created_at
      t.index :updated_at
      t.index %w(project_id iid), name: 'index_requirements_on_project_id_and_iid', where: 'project_id IS NOT NULL', unique: true, using: :btree
    end
  end
  # rubocop:enable Migration/PreventStrings
end
