class CreateGpgSignatures < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :gpg_signatures do |t|
      t.timestamps_with_timezone null: false

      t.references :project, index: true, foreign_key: { on_delete: :cascade }
      t.references :gpg_key, index: true, foreign_key: { on_delete: :nullify }

      t.boolean :valid_signature

      t.binary :commit_sha
      t.binary :gpg_key_primary_keyid

      t.text :gpg_key_user_name
      t.text :gpg_key_user_email

      t.index :commit_sha, unique: true, length: Gitlab::Database.mysql? ? 20 : nil
      t.index :gpg_key_primary_keyid, length: Gitlab::Database.mysql? ? 20 : nil
    end
  end
end
