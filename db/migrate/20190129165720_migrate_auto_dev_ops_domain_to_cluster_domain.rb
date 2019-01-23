# frozen_string_literal: true

class MigrateAutoDevOpsDomainToClusterDomain < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    domains_info = connection.exec_query(project_auto_devops_query).rows
    domains_info.each_slice(1_000) do |batch|
      update_clusters_query = build_clusters_query(Hash[*batch.flatten])

      connection.exec_query(update_clusters_query)
    end
  end

  def down
    # no-op
  end

  private

  def project_auto_devops_table
    @project_auto_devops_table ||= ProjectAutoDevops.arel_table
  end

  def cluster_projects_table
    @cluster_projects_table ||= Clusters::Project.arel_table
  end

  # Fetches ProjectAutoDevops records with:
  # - A domain set
  # - With a Clusters::Project related to Project
  #
  # Returns an array of arrays like:
  # => [
  #     [177, "104.198.38.135.nip.io"],
  #     [178, "35.232.213.111.nip.io"],
  #     ...
  #    ]
  # Where the first element is the Cluster ID and
  # the second element is the domain.
  def project_auto_devops_query
    project_auto_devops_table.join(cluster_projects_table, Arel::Nodes::OuterJoin)
      .on(project_auto_devops_table[:project_id].eq(cluster_projects_table[:project_id]))
      .where(project_auto_devops_table[:domain].not_eq(nil).and(project_auto_devops_table[:domain].not_eq('')))
      .project(cluster_projects_table[:cluster_id], project_auto_devops_table[:domain])
      .to_sql
  end

  # Returns an SQL UPDATE query using a CASE statement
  # to update multiple cluster rows with different values.
  #
  # Example:
  # UPDATE clusters
  # SET domain = (CASE
  #   WHEN id = 177 then '104.198.38.135.nip.io'
  #   WHEN id = 178 then '35.232.213.111.nip.io'
  #   WHEN id = 179 then '35.232.168.149.nip.io'
  #   WHEN id = 180 then '35.224.116.88.nip.io'
  # END)
  # WHERE id IN (177,178,179,180);
  def build_clusters_query(cluster_domains_info)
    <<~HEREDOC
    UPDATE clusters
      SET domain = (CASE
        #{cluster_when_statements(cluster_domains_info)}
      END)
    WHERE id IN (#{cluster_domains_info.keys.join(",")});
    HEREDOC
  end

  def cluster_when_statements(cluster_domains_info)
    cluster_domains_info.map do |cluster_id, domain|
      "WHEN id = #{cluster_id} then '#{domain}'"
    end.join("\n")
  end
end
