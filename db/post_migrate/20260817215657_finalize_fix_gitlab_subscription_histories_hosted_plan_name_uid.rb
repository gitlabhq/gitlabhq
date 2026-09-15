# frozen_string_literal: true

class FinalizeFixGitlabSubscriptionHistoriesHostedPlanNameUid < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    # gitlab_subscription_histories only holds GitLab.com data, so an inline
    # finalize on self-managed touches few or no rows.
    ensure_batched_background_migration_is_finished(
      job_class_name: 'FixGitlabSubscriptionHistoriesHostedPlanNameUid',
      table_name: :gitlab_subscription_histories,
      column_name: :id,
      job_arguments: [],
      finalize: true,
      skip_early_finalization_validation: true
    )
  end

  def down; end
end
