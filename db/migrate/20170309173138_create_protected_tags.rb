class CreateProtectedTags < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  GitlabAccessMaster = 40

  def change
    create_table :protected_tags do |t|
      t.integer :project_id, null: false
      t.string :name, null: false
      t.string :timestamps #TODO: `null: false`? Missing from protected_branches
    end

    add_index :protected_tags, :project_id

    create_table :protected_tag_merge_access_levels do |t|
      t.references :protected_tag, index: { name: "index_protected_tag_merge_access" }, foreign_key: true, null: false

      t.integer :access_level, default: GitlabAccessMaster, null: true #TODO: was false, check schema
      t.integer :group_id #TODO: check why group/user id missing from CE
      t.integer :user_id
      t.timestamps null: false
    end

    create_table :protected_tag_push_access_levels do |t|
      t.references :protected_tag, index: { name: "index_protected_tag_push_access" }, foreign_key: true, null: false
      t.integer :access_level, default: GitlabAccessMaster, null: true #TODO: was false, check schema
      t.integer :group_id
      t.integer :user_id
      t.timestamps null: false
    end

    #TODO: These had rubocop set to disable Migration/AddConcurrentForeignKey
    # add_foreign_key :protected_tag_merge_access_levels, :namespaces, column: :group_id 
    # add_foreign_key :protected_tag_push_access_levels, :namespaces, column: :group_id
  end
end
