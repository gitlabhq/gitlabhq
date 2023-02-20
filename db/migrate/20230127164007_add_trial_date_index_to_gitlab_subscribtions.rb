# frozen_string_literal: true

class AddTrialDateIndexToGitlabSubscribtions < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_gitlab_subscriptions_on_trial_and_trial_starts_on'

  def up
    add_concurrent_index :gitlab_subscriptions, [:trial, :trial_starts_on], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :gitlab_subscriptions, INDEX_NAME
  end
end
