# frozen_string_literal: true

class DeleteOrphanedPipelineExecutionProjectSchedules < Gitlab::Database::Migration[2.4]
  milestone '19.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!

  # About 36.8k rows on GitLab.com (31 orphans) -> 37 batches of 1,000, each a primary-key
  # range scan plus one link-index lookup per row; roughly 130 ms per batch warm.
  BATCH_SIZE = 1_000

  class PipelineExecutionProjectSchedule < MigrationRecord
    include EachBatch

    self.table_name = 'security_pipeline_execution_project_schedules'
  end

  # A schedule is orphaned once its (project_id, security_policy_id) pair no longer has a
  # matching security_policy_project_links row, e.g. when a project is transferred out of the
  # group that owns the policy.
  def up
    schedules_table = PipelineExecutionProjectSchedule.arel_table
    links_table = Arel::Table.new(:security_policy_project_links)

    link_not_exists = Arel::Nodes::Not.new(
      Arel::Nodes::Exists.new(
        links_table.where(
          links_table[:project_id].eq(schedules_table[:project_id])
            .and(links_table[:security_policy_id].eq(schedules_table[:security_policy_id]))
        )
      )
    )

    PipelineExecutionProjectSchedule.each_batch(of: BATCH_SIZE) do |batch|
      batch.where(link_not_exists).delete_all
    end
  end

  def down
    # no-op: deleted rows cannot be restored
  end
end
