# rubocop:disable Migration/Timestamps
class InitEESchema < ActiveRecord::Migration
  DOWNTIME = false

  def up
    add_column :namespaces, :ldap_cn, :string, null: true
    add_column :namespaces, :ldap_access, :integer, null: true

    create_table :git_hooks do |t|
      t.string :force_push_regex
      t.string :delete_branch_regex
      t.string :commit_message_regex
      t.boolean :deny_delete_tag
      t.integer :project_id

      t.timestamps null: true
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "The initial migration is not revertable"
  end
end
