# frozen_string_literal: true

class BackfillDeploymentsFinishedAt < Gitlab::Database::Migration[2.0]
  DEPLOYMENT_STATUS_SUCCESS = 2 # Equivalent to Deployment.statuses[:success]

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  BATCH_SIZE = 100

  def up
    define_batchable_model('deployments')
      .where(finished_at: nil)
      .where(status: DEPLOYMENT_STATUS_SUCCESS)
      .each_batch(of: BATCH_SIZE) { |relation| relation.update_all('finished_at = created_at') }
  end

  def down
    # no-op
  end
end
