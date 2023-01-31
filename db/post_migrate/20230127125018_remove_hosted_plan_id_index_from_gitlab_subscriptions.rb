# frozen_string_literal: true

class RemoveHostedPlanIdIndexFromGitlabSubscriptions < Gitlab::Database::Migration[2.1]
  OLD_INDEX_NAME = 'index_gitlab_subscriptions_on_hosted_plan_id'
  NEW_INDEX_NAME = 'index_gitlab_subscriptions_on_hosted_plan_id_and_trial'
  TABLE = :gitlab_subscriptions

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name TABLE, OLD_INDEX_NAME if index_exists_by_name?(TABLE, NEW_INDEX_NAME)
  end

  def down
    add_concurrent_index TABLE, :hosted_plan_id, name: OLD_INDEX_NAME
  end
end
