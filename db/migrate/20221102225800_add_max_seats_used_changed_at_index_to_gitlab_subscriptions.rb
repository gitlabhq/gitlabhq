# frozen_string_literal: true

class AddMaxSeatsUsedChangedAtIndexToGitlabSubscriptions < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_gitlab_subscriptions_on_max_seats_used_changed_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :gitlab_subscriptions, [:max_seats_used_changed_at, :namespace_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :gitlab_subscriptions, INDEX_NAME
  end
end
