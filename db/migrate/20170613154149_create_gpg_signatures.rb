class CreateGpgSignatures < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :gpg_signatures do |t|
      t.string :commit_sha
      t.references :project, index: true, foreign_key: true
      t.references :gpg_key, index: true, foreign_key: true
      t.string :gpg_key_primary_keyid
      t.boolean :valid_signature

      t.timestamps_with_timezone null: false
    end

    add_concurrent_index :gpg_signatures, :commit_sha
    add_concurrent_index :gpg_signatures, :gpg_key_primary_keyid
  end

  def down
    remove_concurrent_index :gpg_signatures, :commit_sha if index_exists?(:gpg_signatures, :commit_sha)
    remove_concurrent_index :gpg_signatures, :gpg_key_primary_keyid if index_exists?(:gpg_signatures, :gpg_key_primary_keyid)

    drop_table :gpg_signatures
  end
end
