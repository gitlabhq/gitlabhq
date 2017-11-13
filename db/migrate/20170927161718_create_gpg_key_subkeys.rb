class CreateGpgKeySubkeys < ActiveRecord::Migration
  DOWNTIME = false

  def up
    create_table :gpg_key_subkeys do |t|
      t.references :gpg_key, null: false, index: true, foreign_key: { on_delete: :cascade }

      t.binary :keyid
      t.binary :fingerprint

      t.index :keyid, unique: true, length: Gitlab::Database.mysql? ? 20 : nil
      t.index :fingerprint, unique: true, length: Gitlab::Database.mysql? ? 20 : nil
    end

    add_reference :gpg_signatures, :gpg_key_subkey, index: true, foreign_key: { on_delete: :nullify }
  end

  def down
    remove_reference(:gpg_signatures, :gpg_key_subkey, index: true, foreign_key: true)

    drop_table :gpg_key_subkeys
  end
end
