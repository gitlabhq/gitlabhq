# frozen_string_literal: true

class AddTrigramIndexOnPublicEmailForUsers < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!

  INDEX_NAME = 'index_users_on_public_email_trigram'

  def up
    return if Gitlab.com_except_jh?

    # rubocop:disable Migration/PreventIndexCreation -- index for self-managed instance
    add_concurrent_index :users, :public_email, name: INDEX_NAME, using: :gin, opclass: { public_email: :gin_trgm_ops }
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    return if Gitlab.com_except_jh?

    remove_concurrent_index_by_name :users, INDEX_NAME
  end
end
