class CreateGpgKeys < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :gpg_keys do |t|
      t.timestamps_with_timezone null: false

      t.references :user, index: true, foreign_key: { on_delete: :cascade }

      t.binary :primary_keyid
      t.binary :fingerprint

      t.text :key

      t.index :primary_keyid, unique: true, length: Gitlab::Database.mysql? ? 20 : nil
      t.index :fingerprint, unique: true, length: Gitlab::Database.mysql? ? 20 : nil
    end
  end
end
