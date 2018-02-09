class CreateForkNetworks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :fork_networks do |t|
      t.references :root_project,
                   references: :projects,
                   index: { unique: true }

      t.string :deleted_root_project_name
    end

    add_concurrent_foreign_key :fork_networks, :projects,
                               column: :root_project_id,
                               on_delete: :nullify
  end

  def down
    if foreign_keys_for(:fork_networks, :root_project_id).any?
      remove_foreign_key :fork_networks, column: :root_project_id
    end

    drop_table :fork_networks
  end
end
