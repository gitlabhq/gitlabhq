class CreateGpgKeySubkeys < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :gpg_key_subkeys do |t|
      t.binary :keyid
      t.binary :fingerprint
      t.references :gpg_key, null: false, index: true, foreign_key: { on_delete: :cascade }
    end
  end
end
