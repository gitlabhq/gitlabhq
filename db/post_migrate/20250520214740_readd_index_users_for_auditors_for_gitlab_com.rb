# frozen_string_literal: true

class ReaddIndexUsersForAuditorsForGitlabCom < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  TABLE_NAME = :users
  INDEX_NAME = :index_users_for_auditors

  def up
    return unless should_run?

    add_concurrent_index TABLE_NAME, :id, where: 'auditor IS true', name: INDEX_NAME
  end

  def down
    return unless should_run?

    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def should_run?
    Gitlab.com_except_jh?
  end
end
