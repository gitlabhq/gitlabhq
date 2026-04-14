# frozen_string_literal: true

class AddFingerprintDataToArkoseSessions < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :arkose_sessions, :ja4_hash, :text, null: true, if_not_exists: true
      add_column :arkose_sessions, :canvas_fingerprint, :bigint, null: true, if_not_exists: true
    end

    add_text_limit :arkose_sessions, :ja4_hash, 64
  end

  def down
    with_lock_retries do
      remove_column :arkose_sessions, :ja4_hash, if_exists: true
      remove_column :arkose_sessions, :canvas_fingerprint, if_exists: true
    end
  end
end
