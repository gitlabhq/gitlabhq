# frozen_string_literal: true

class DropIndexUsersForAuditorsForGitlabCom < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  TABLE_NAME = :users
  INDEX_NAME = :index_users_for_auditors

  def up
    return unless should_run?

    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    return unless should_run?

    add_concurrent_index TABLE_NAME, :created_at, name: INDEX_NAME
  end

  def should_run?
    Gitlab.com_except_jh?
  end
end
