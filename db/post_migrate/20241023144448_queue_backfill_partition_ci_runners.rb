# frozen_string_literal: true

class QueueBackfillPartitionCiRunners < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.6'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'BackfillCiRunnersPartitionedTable'
  TABLE_NAME = 'ci_runners'

  def up
    # no-op because we lost some group and project runners due to LFKs, which have been
    # removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176804
  end

  def down
    # no-op because we lost some group and project runners due to LFKs, which have been
    # removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176804
  end
end
