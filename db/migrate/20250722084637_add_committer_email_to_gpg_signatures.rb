# frozen_string_literal: true

class AddCommitterEmailToGpgSignatures < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :gpg_signatures, :committer_email, :text, if_not_exists: true
    end

    add_text_limit :gpg_signatures, :committer_email, 255
  end

  def down
    with_lock_retries do
      remove_column :gpg_signatures, :committer_email, if_exists: true
    end
  end
end
