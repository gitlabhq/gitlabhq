# frozen_string_literal: true

class RemoveGpgSignaturesAuthorEmailColumn < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.5'

  def up
    remove_column :gpg_signatures, :author_email
  end

  def down
    add_column :gpg_signatures, :author_email, :text, if_not_exists: true

    add_text_limit :gpg_signatures, :author_email, 255
  end
end
