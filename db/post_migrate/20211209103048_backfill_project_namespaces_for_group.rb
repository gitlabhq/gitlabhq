# frozen_string_literal: true

class BackfillProjectNamespacesForGroup < Gitlab::Database::Migration[1.0]
  MIGRATION = 'ProjectNamespaces::BackfillProjectNamespaces'
  DELAY_INTERVAL = 2.minutes
  GROUP_ID = 9970 # picking gitlab-org group.

  disable_ddl_transaction!

  def up
    return unless Gitlab.com? || Gitlab.staging?

    projects_table = ::Gitlab::BackgroundMigration::ProjectNamespaces::Models::Project.arel_table
    hierarchy_cte_sql = Arel.sql(::Gitlab::BackgroundMigration::ProjectNamespaces::BackfillProjectNamespaces.hierarchy_cte(GROUP_ID))
    group_projects = ::Gitlab::BackgroundMigration::ProjectNamespaces::Models::Project.where(projects_table[:namespace_id].in(hierarchy_cte_sql))

    min_id = group_projects.minimum(:id)
    max_id = group_projects.maximum(:id)

    return if min_id.blank? || max_id.blank?

    queue_batched_background_migration(
      MIGRATION,
      :projects,
      :id,
      GROUP_ID,
      'up',
      job_interval: DELAY_INTERVAL,
      batch_min_value: min_id,
      batch_max_value: max_id,
      sub_batch_size: 25,
      batch_class_name: 'BackfillProjectNamespacePerGroupBatchingStrategy'
    )
  end

  def down
    return unless Gitlab.com? || Gitlab.staging?

    delete_batched_background_migration(MIGRATION, :projects, :id, [GROUP_ID, 'up'])
  end
end
