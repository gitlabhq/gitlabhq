# frozen_string_literal: true

class AddSprints < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :sprints, id: :bigserial do |t|
      t.timestamps_with_timezone null: false
      t.date :start_date
      t.date :due_date

      t.references :project, foreign_key: false, index: false
      t.references :group, foreign_key: false, index: true

      t.integer :iid, null: false
      t.integer :cached_markdown_version
      t.integer :state, limit: 2
      # rubocop:disable Migration/AddLimitToTextColumns
      t.text :title, null: false
      t.text :title_html
      t.text :description
      t.text :description_html
      # rubocop:enable Migration/AddLimitToTextColumns

      t.index :description, name: "index_sprints_on_description_trigram", opclass: :gin_trgm_ops, using: :gin
      t.index :due_date
      t.index %w(project_id iid), unique: true
      t.index :title
      t.index :title, name: "index_sprints_on_title_trigram", opclass: :gin_trgm_ops, using: :gin

      t.index %w(project_id title), unique: true, where: 'project_id IS NOT NULL'
      t.index %w(group_id title), unique: true, where: 'group_id IS NOT NULL'
    end
  end
end
