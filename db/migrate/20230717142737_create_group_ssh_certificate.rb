# frozen_string_literal: true

class CreateGroupSshCertificate < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    create_table :group_ssh_certificates do |t|
      t.references :namespace, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.datetime_with_timezone :created_at, null: false
      t.binary :fingerprint, null: false
      t.text :title, null: false, limit: 256
      t.text :key, null: false, limit: 512.kilobytes

      t.index :fingerprint, unique: true
    end
  end
end
