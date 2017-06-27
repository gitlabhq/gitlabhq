# rubocop:disable Migration/Timestamps
class CreateProtectedTags < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  GITLAB_ACCESS_MASTER = 40

  def change
    create_table :protected_tags do |t|
      t.integer :project_id, null: false
      t.string :name, null: false
      t.timestamps null: false
    end

    add_index :protected_tags, :project_id

    create_table :protected_tag_create_access_levels do |t|
      t.references :protected_tag, index: { name: "index_protected_tag_create_access" }, foreign_key: true, null: false
      t.integer :access_level, default: GITLAB_ACCESS_MASTER, null: true
      t.references :user, foreign_key: true, index: true
      t.integer :group_id
      t.timestamps null: false
    end

    add_foreign_key :protected_tag_create_access_levels, :namespaces, column: :group_id # rubocop: disable Migration/AddConcurrentForeignKey
  end
end
