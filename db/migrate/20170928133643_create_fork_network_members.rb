class CreateForkNetworkMembers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :fork_network_members do |t|
      t.references :fork_network, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.references :project, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.references :forked_from_project, references: :projects
    end

    add_concurrent_foreign_key :fork_network_members, :projects,
                               column: :forked_from_project_id,
                               on_delete: :nullify
  end

  def down
    if foreign_keys_for(:fork_network_members, :forked_from_project_id).any?
      remove_foreign_key :fork_network_members, column: :forked_from_project_id
    end

    drop_table :fork_network_members
  end
end
