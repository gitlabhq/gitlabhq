# frozen_string_literal: true

class CreateSshSignatures < Gitlab::Database::Migration[2.0]
  def change
    create_table :ssh_signatures do |t|
      t.timestamps_with_timezone null: false
      t.bigint :project_id, null: false, index: true
      t.bigint :key_id, null: false, index: true
      t.integer :verification_status, default: 0, null: false, limit: 2
      t.binary :commit_sha, null: false, index: { unique: true }
    end
  end
end
