class CreateGpgSignatures < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :gpg_signatures do |t|
      t.timestamps_with_timezone null: false

      t.references :project, index: true, foreign_key: true
      t.references :gpg_key, index: true, foreign_key: true

      t.boolean :valid_signature

      t.string :commit_sha
      t.string :gpg_key_primary_keyid
      t.string :gpg_key_user_name
      t.string :gpg_key_user_email

      t.index :commit_sha
      t.index :gpg_key_primary_keyid
    end
  end
end
