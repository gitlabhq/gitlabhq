# frozen_string_literal: true

class AddIndexOnHostedPlanNameUidToGitlabSubscriptionHistories < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_gitlab_subscription_histories_on_hosted_plan_name_uid'

  def up
    add_concurrent_index :gitlab_subscription_histories, :hosted_plan_name_uid, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :gitlab_subscription_histories, INDEX_NAME
  end
end
