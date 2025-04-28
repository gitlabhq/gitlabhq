# frozen_string_literal: true

class AddAuthorEmailLimitToSshSignatures < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '18.0'

  def up
    add_text_limit :ssh_signatures, :author_email, 255
  end

  def down
    remove_text_limit :ssh_signatures, :author_email
  end
end
