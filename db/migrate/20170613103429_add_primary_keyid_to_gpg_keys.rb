class AddPrimaryKeyidToGpgKeys < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :gpg_keys, :primary_keyid, :string
    add_concurrent_index :gpg_keys, :primary_keyid
  end

  def down
    remove_concurrent_index :gpg_keys, :primary_keyid if index_exists?(:gpg_keys, :primary_keyid)
    remove_column :gpg_keys, :primary_keyid, :string
  end
end
