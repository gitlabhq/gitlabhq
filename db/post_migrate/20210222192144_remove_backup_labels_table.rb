# frozen_string_literal: true

class RemoveBackupLabelsTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    drop_table :backup_labels
  end

  def down
    create_table :backup_labels, id: false do |t|
      t.integer :id, null: false
      t.string :title
      t.string :color
      t.integer :project_id
      t.timestamps null: true # rubocop:disable Migration/Timestamps
      t.boolean :template, default: false
      t.string :description
      t.text :description_html
      t.string :type
      t.integer :group_id
      t.integer :cached_markdown_version
      t.integer :restore_action
      t.string :new_title
    end

    execute 'ALTER TABLE backup_labels ADD PRIMARY KEY (id)'

    add_index :backup_labels, [:group_id, :project_id, :title], name: 'backup_labels_group_id_project_id_title_idx', unique: true
    add_index :backup_labels, [:group_id, :title], where: 'project_id = NULL::integer', name: 'backup_labels_group_id_title_idx'
    add_index :backup_labels, :project_id, name: 'backup_labels_project_id_idx'
    add_index :backup_labels, :template, name: 'backup_labels_template_idx', where: 'template'
    add_index :backup_labels, :title, name: 'backup_labels_title_idx'
    add_index :backup_labels, [:type, :project_id], name: 'backup_labels_type_project_id_idx'
  end
end
