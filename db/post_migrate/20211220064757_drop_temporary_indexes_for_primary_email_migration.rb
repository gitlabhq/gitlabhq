# frozen_string_literal: true

class DropTemporaryIndexesForPrimaryEmailMigration < Gitlab::Database::Migration[1.0]
  USERS_INDEX = :index_users_on_id_for_primary_email_migration
  EMAIL_INDEX = :index_emails_on_email_user_id

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :users, USERS_INDEX
    remove_concurrent_index_by_name :emails, EMAIL_INDEX
  end

  def down
    unless index_exists_by_name?(:users, USERS_INDEX)

      disable_statement_timeout do
        execute <<~SQL
        CREATE INDEX CONCURRENTLY #{USERS_INDEX}
        ON users (id) INCLUDE (email, confirmed_at)
        WHERE confirmed_at IS NOT NULL
        SQL
      end
    end

    add_concurrent_index :emails, [:email, :user_id], name: EMAIL_INDEX
  end
end
