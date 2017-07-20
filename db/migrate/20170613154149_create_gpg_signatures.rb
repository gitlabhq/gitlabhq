class CreateGpgSignatures < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :gpg_signatures do |t|
      t.timestamps_with_timezone null: false

      t.references :project, index: true, foreign_key: true
      t.references :gpg_key, index: true, foreign_key: true

      t.boolean :valid_signature

      t.binary :commit_sha, limit: Gitlab::Database.mysql? ? 20 : nil
      t.binary :gpg_key_primary_keyid, limit: Gitlab::Database.mysql? ? 20 : nil

      t.text :gpg_key_user_name
      t.text :gpg_key_user_email

      t.index :commit_sha
      t.index :gpg_key_primary_keyid
    end
  end
end
