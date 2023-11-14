# frozen_string_literal: true

class IndexUsersOnEmailDomainAndId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_users_on_email_domain_and_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation
    add_concurrent_index(:users, "lower(split_part(email, '@', 2)), id", name: INDEX_NAME)
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :users, INDEX_NAME
  end
end
