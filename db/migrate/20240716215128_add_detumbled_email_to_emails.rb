# frozen_string_literal: true

class AddDetumbledEmailToEmails < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.3'

  def up
    with_lock_retries do
      add_column :emails, :detumbled_email, :text, if_not_exists: true
    end

    add_text_limit :emails, :detumbled_email, 255
  end

  def down
    remove_column :emails, :detumbled_email, if_exists: true
  end
end
