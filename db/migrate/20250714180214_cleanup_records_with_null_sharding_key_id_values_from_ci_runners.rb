# frozen_string_literal: true

class CleanupRecordsWithNullShardingKeyIdValuesFromCiRunners < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  BATCH_SIZE = 1000

  class CiRunner < MigrationRecord
    include EachBatch

    self.table_name = 'ci_runners'
    self.primary_key = :id
  end

  def up
    # no-op to fix https://gitlab.com/gitlab-com/gl-infra/production/-/issues/20245
  end

  def down
    # no-op to fix https://gitlab.com/gitlab-com/gl-infra/production/-/issues/20245
  end
end
