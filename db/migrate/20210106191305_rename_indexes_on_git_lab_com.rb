# frozen_string_literal: true

# This migration aligns an existing database schema with what we actually expect
# and fixes inconsistencies with index names and similar issues.
#
# This is intended for GitLab.com, but can be run on any instance.
class RenameIndexesOnGitLabCom < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    rename_index_if_exists :ldap_group_links, 'ldap_groups_pkey', 'ldap_group_links_pkey'

    # Removes unique constraint, add unique index instead
    replace_unique_constraint_with_index :emails, :email, 'emails_email_key', 'index_emails_on_email'
    replace_unique_constraint_with_index :users, :confirmation_token, 'users_confirmation_token_key', 'index_users_on_confirmation_token'
    replace_unique_constraint_with_index :users, :reset_password_token, 'users_reset_password_token_key', 'index_users_on_reset_password_token'
    replace_unique_constraint_with_index :users, :email, 'users_email_key', 'index_users_on_email'

    upgrade_to_primary_key(:schema_migrations, :version, 'schema_migrations_version_key', 'schema_migrations_pkey')
  end

  def down
    # no-op
  end

  private

  def replace_unique_constraint_with_index(table, columns, old_name, new_name)
    return unless index_exists_by_name?(table, old_name)

    add_concurrent_index table, columns, unique: true, name: new_name
    execute "ALTER TABLE #{quote_table_name(table)} DROP CONSTRAINT #{quote_table_name(old_name)}"
  end

  def rename_index_if_exists(table, old_name, new_name)
    return unless index_exists_by_name?(table, old_name)
    return if index_exists_by_name?(table, new_name)

    with_lock_retries do
      rename_index table, old_name, new_name
    end
  end

  def upgrade_to_primary_key(table, column, old_name, new_name)
    return unless index_exists_by_name?(table, old_name)
    return if index_exists_by_name?(table, new_name)

    return if primary_key(table)

    execute "ALTER TABLE #{quote_table_name(table)} ADD CONSTRAINT #{new_name} PRIMARY KEY (#{column})"
    execute "ALTER TABLE #{quote_table_name(table)} DROP CONSTRAINT #{old_name}"
  end
end
