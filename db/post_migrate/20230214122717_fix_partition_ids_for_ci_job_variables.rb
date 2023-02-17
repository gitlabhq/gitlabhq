# frozen_string_literal: true

class FixPartitionIdsForCiJobVariables < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  BATCH_SIZE = 50

  def up
    return unless Gitlab.com?

    define_batchable_model(:ci_job_variables)
      .where(partition_id: 101)
      .each_batch(of: BATCH_SIZE) do |batch|
        batch.update_all(partition_id: 100)
        sleep 0.1
      end
  end

  def down
    # no-op
  end
end
