class CreateGpgKeys < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :gpg_keys do |t|
      t.string :fingerprint
      t.text :key
      t.references :user, index: true, foreign_key: true

      t.timestamps_with_timezone null: false
    end
  end
end
