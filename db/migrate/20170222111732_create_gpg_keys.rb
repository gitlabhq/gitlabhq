class CreateGpgKeys < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :gpg_keys do |t|
      t.timestamps_with_timezone null: false

      t.references :user, index: true, foreign_key: { on_delete: :cascade }

      t.binary :primary_keyid, limit: Gitlab::Database.mysql? ? 20 : nil
      t.binary :fingerprint, limit: Gitlab::Database.mysql? ? 20 : nil

      t.text :key

      t.index :primary_keyid
    end
  end
end
