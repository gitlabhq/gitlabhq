# frozen_string_literal: true

class AddIndexGitlabSubscriptionHistoriesOnChangeTypeAndHostedPlanId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  OLD_INDEX_NAME = 'index_gitlab_subscription_histories_on_namespace_id'
  INDEX_NAME = 'i_gitlab_subscription_histories_on_namespace_change_type_plan'

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :gitlab_subscription_histories, [:namespace_id, :change_type, :hosted_plan_id], name: INDEX_NAME
    )

    remove_concurrent_index_by_name :gitlab_subscription_histories, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :gitlab_subscription_histories, :namespace_id, name: OLD_INDEX_NAME

    remove_concurrent_index_by_name :gitlab_subscription_histories, INDEX_NAME
  end
end
