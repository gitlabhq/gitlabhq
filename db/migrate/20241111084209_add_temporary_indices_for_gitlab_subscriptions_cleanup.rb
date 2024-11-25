# frozen_string_literal: true

class AddTemporaryIndicesForGitlabSubscriptionsCleanup < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  INDEX_NAME_TRIAL_DATES_NULL = 'tmp_index_gitlab_subscriptions_on_id_where_trial_dates_null'
  INDEX_NAME_TRIAL_START_EQ_END = 'tmp_index_gitlab_subscriptions_on_id_where_trial_start_eq_end'

  def up
    add_concurrent_index(
      :gitlab_subscriptions,
      :id,
      where: 'trial = TRUE and (trial_starts_on IS NULL or trial_ends_on IS NULL)',
      name: INDEX_NAME_TRIAL_DATES_NULL
    )
    add_concurrent_index(
      :gitlab_subscriptions,
      :id,
      where: 'trial = TRUE AND trial_starts_on = trial_ends_on',
      name: INDEX_NAME_TRIAL_START_EQ_END
    )
  end

  def down
    remove_concurrent_index_by_name(
      :gitlab_subscriptions,
      INDEX_NAME_TRIAL_DATES_NULL
    )
    remove_concurrent_index_by_name(
      :gitlab_subscriptions,
      INDEX_NAME_TRIAL_START_EQ_END
    )
  end
end
