class CreateGpgKeySubkeys < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_table :gpg_key_subkeys do |t|
      t.references :gpg_key, null: false, index: true, foreign_key: { on_delete: :cascade }

      t.binary :keyid
      t.binary :fingerprint

      t.index :keyid, unique: true, length: mysql_compatible_index_length
      t.index :fingerprint, unique: true, length: mysql_compatible_index_length
    end

    add_reference :gpg_signatures, :gpg_key_subkey, index: true, foreign_key: { on_delete: :nullify }
  end

  def down
    remove_reference(:gpg_signatures, :gpg_key_subkey, index: true, foreign_key: true)

    drop_table :gpg_key_subkeys
  end
end
