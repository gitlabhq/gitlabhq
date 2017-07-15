class CreateGpgKeys < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :gpg_keys do |t|
      t.timestamps_with_timezone null: false

      t.references :user, index: true, foreign_key: true

      t.string :fingerprint
      t.string :primary_keyid

      t.text :key

      t.index :primary_keyid
    end
  end
end
