# frozen_string_literal: true

class DropIndexUsersOnEmailTrigram < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  TABLE_NAME = :users
  INDEX_NAME = :index_users_on_email_trigram

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :email, name: INDEX_NAME,
      using: :gin, opclass: { email: :gin_trgm_ops }
  end
end
