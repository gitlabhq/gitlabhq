# frozen_string_literal: true

class DropIdxNamespacesOnLdapSyncLastSuccessfulUpdateAtForGitlab < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  disable_ddl_transaction!

  TABLE_NAME = :namespaces
  INDEX_NAME = :index_namespaces_on_ldap_sync_last_successful_update_at

  def up
    return unless should_run?

    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    return unless should_run?

    add_concurrent_index TABLE_NAME, :ldap_sync_last_successful_update_at, name: INDEX_NAME
  end

  private

  def should_run?
    Gitlab.com_except_jh?
  end
end
