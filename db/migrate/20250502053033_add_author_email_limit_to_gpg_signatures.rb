# frozen_string_literal: true

class AddAuthorEmailLimitToGpgSignatures < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.0'

  def up
    add_text_limit :gpg_signatures, :author_email, 255
  end

  def down
    remove_text_limit :gpg_signatures, :author_email
  end
end
