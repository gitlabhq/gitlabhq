# frozen_string_literal: true

class AddHostedPlanIdAndTrialIndexToGitlabSubscriptions < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_gitlab_subscriptions_on_hosted_plan_id_and_trial'

  disable_ddl_transaction!

  def up
    add_concurrent_index :gitlab_subscriptions, [:hosted_plan_id, :trial], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :gitlab_subscriptions, INDEX_NAME
  end
end
