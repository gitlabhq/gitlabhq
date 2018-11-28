# rubocop:disable RemoveIndex
class AddUniqueIndexToKeysFingerprint < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_index :keys, :fingerprint, unique: true
  end

  def down
    remove_index :keys, :fingerprint
  end
end
