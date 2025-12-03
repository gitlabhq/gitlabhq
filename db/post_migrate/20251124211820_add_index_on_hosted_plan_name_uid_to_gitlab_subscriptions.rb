# frozen_string_literal: true

class AddIndexOnHostedPlanNameUidToGitlabSubscriptions < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_gitlab_subscriptions_on_hosted_plan_name_uid_and_trial'

  def up
    add_concurrent_index :gitlab_subscriptions, [:hosted_plan_name_uid, :trial], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :gitlab_subscriptions, INDEX_NAME
  end
end
