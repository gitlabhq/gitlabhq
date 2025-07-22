# frozen_string_literal: true

class CleanupRecordsWithNullShardingKeyIdValuesFromCiRunnerTaggings < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  BATCH_SIZE = 1000

  class CiRunnerTagging < MigrationRecord
    include EachBatch

    self.table_name = 'ci_runner_taggings'
    self.primary_key = :id
  end

  def up
    # no-op - this migration is required to allow a rollback of `RemoveShardingKeyCheckConstraintFromCiRunnerTaggings`
  end

  def down
    CiRunnerTagging.each_batch(of: BATCH_SIZE) do |relation|
      relation.where.not(runner_type: 1).where(sharding_key_id: nil).delete_all
    end
  end
end
