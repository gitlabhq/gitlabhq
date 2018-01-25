# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateEpics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :epics do |t|
      t.references :milestone, index: { name: 'index_milestone' }, foreign_key: { on_delete: :nullify }
      t.integer :group_id, null: false, index: true
      t.integer :author_id, null: false, index: true
      t.integer :assignee_id, index: true
      t.integer :iid, null: false, index: true
      t.integer :cached_markdown_version, limit: 4
      t.integer :updated_by_id
      t.integer :last_edited_by_id
      t.integer :lock_version
      t.date :start_date
      t.date :end_date
      t.datetime_with_timezone :last_edited_at
      t.timestamps_with_timezone
      t.string :title, null: false
      t.string :title_html, null: false
      t.text :description
      t.text :description_html
    end

    add_concurrent_foreign_key :epics, :namespaces, column: :group_id
    add_concurrent_foreign_key :epics, :users, column: :author_id
    add_concurrent_foreign_key :epics, :users, column: :assignee_id, on_delete: :nullify

    create_table :epic_metrics do |t|
      t.references :epic, index: { name: "index_epic_metrics" }, foreign_key: { on_delete: :cascade }, null: false

      t.timestamps_with_timezone
    end
  end

  def down
    remove_foreign_key :epics, column: :group_id
    remove_foreign_key :epics, column: :author_id
    remove_foreign_key :epics, column: :assignee_id
    remove_foreign_key :epics, column: :milestone_id
    remove_foreign_key :epic_metrics, column: :epic_id

    drop_table :epics
    drop_table :epic_metrics
  end
end
