# frozen_string_literal: true

class AddIndexGitlabSubscriptionHistoryOnNamespaceId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  TABLE_NAME = :gitlab_subscription_histories
  INDEX_NAME = 'index_gitlab_subscription_histories_on_namespace_id'

  def up
    add_concurrent_index(
      TABLE_NAME,
      :namespace_id,
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, name: INDEX_NAME)
  end
end
