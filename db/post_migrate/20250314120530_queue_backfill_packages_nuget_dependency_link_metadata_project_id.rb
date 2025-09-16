# frozen_string_literal: true

class QueueBackfillPackagesNugetDependencyLinkMetadataProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillPackagesNugetDependencyLinkMetadataProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :packages_nuget_dependency_link_metadata,
      :dependency_link_id,
      :project_id,
      :packages_dependency_links,
      :project_id,
      :dependency_link_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :packages_nuget_dependency_link_metadata,
      :dependency_link_id,
      [
        :project_id,
        :packages_dependency_links,
        :project_id,
        :dependency_link_id
      ]
    )
  end
end
