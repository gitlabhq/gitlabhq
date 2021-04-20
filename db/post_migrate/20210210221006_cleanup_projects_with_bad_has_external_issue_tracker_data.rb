# frozen_string_literal: true

class CleanupProjectsWithBadHasExternalIssueTrackerData < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  TMP_INDEX_NAME = 'tmp_idx_projects_on_id_where_has_external_issue_tracker_is_true'
  BATCH_SIZE = 100

  disable_ddl_transaction!

  class Service < ActiveRecord::Base
    include EachBatch
    belongs_to :project

    self.table_name = 'services'
    self.inheritance_column = :_type_disabled
  end

  class Project < ActiveRecord::Base
    include EachBatch

    self.table_name = 'projects'
  end

  def up
    update_projects_with_active_external_issue_trackers
    update_projects_without_active_external_issue_trackers
  end

  def down
    # no-op : can't go back to incorrect data
  end

  private

  def update_projects_with_active_external_issue_trackers
    scope = Service.where(active: true, category: 'issue_tracker').where.not(project_id: nil).distinct(:project_id)

    scope.each_batch(of: BATCH_SIZE) do |relation|
      scope_with_projects = relation
        .joins(:project)
        .select('project_id')
        .merge(Project.where(has_external_issue_tracker: false).where(pending_delete: false))

      execute(<<~SQL)
      WITH project_ids_to_update (id) AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
        #{scope_with_projects.to_sql}
      )
      UPDATE projects SET has_external_issue_tracker = true WHERE id IN (SELECT id FROM project_ids_to_update)
      SQL
    end
  end

  def update_projects_without_active_external_issue_trackers
    # Add a temporary index to speed up the scoping of projects.
    index_where = <<~SQL
      "projects"."has_external_issue_tracker" = TRUE
      AND "projects"."pending_delete" = FALSE
    SQL

    add_concurrent_index(:projects, :id, where: index_where, name: TMP_INDEX_NAME)

    services_sub_query = Service
      .select('1')
      .where('services.project_id = projects.id')
      .where(category: 'issue_tracker')
      .where(active: true)

    # 322 projects are scoped in this query on GitLab.com.
    Project.where(index_where).each_batch(of: BATCH_SIZE) do |relation|
      relation_with_exists_query = relation.where('NOT EXISTS (?)', services_sub_query)
      execute(<<~SQL)
      WITH project_ids_to_update (id) AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
        #{relation_with_exists_query.select(:id).to_sql}
      )
      UPDATE projects SET has_external_issue_tracker = false WHERE id IN (SELECT id FROM project_ids_to_update)
      SQL
    end

    # Drop the temporary index.
    remove_concurrent_index_by_name(:projects, TMP_INDEX_NAME)
  end
end
