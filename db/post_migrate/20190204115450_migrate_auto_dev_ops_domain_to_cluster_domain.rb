# frozen_string_literal: true

class MigrateAutoDevOpsDomainToClusterDomain < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    execute(update_clusters_domain_query)
  end

  def down
    # no-op
  end

  private

  def update_clusters_domain_query
    <<~HEREDOC
    UPDATE clusters
    SET domain = project_auto_devops.domain
    FROM cluster_projects, project_auto_devops
    WHERE
      cluster_projects.cluster_id = clusters.id
      AND project_auto_devops.project_id = cluster_projects.project_id
      AND project_auto_devops.domain != ''
    HEREDOC
  end
end
