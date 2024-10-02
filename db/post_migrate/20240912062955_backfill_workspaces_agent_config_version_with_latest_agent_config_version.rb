# frozen_string_literal: true

class BackfillWorkspacesAgentConfigVersionWithLatestAgentConfigVersion < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute(<<-SQL)
      UPDATE workspaces
        SET workspaces_agent_config_version = subquery.version_count
        FROM (
          SELECT
            config_table.cluster_agent_id,
            COUNT(*) AS version_count
          FROM
            workspaces_agent_config_versions
          LEFT JOIN
            workspaces_agent_configs AS config_table
            ON workspaces_agent_config_versions.item_id = config_table.id
          GROUP BY
            config_table.cluster_agent_id
        ) AS subquery
        WHERE
          workspaces.cluster_agent_id = subquery.cluster_agent_id
          AND workspaces.workspaces_agent_config_version IS NULL;
    SQL

    # any un-updated column should have version of 0, as there is no agent_cofig_version in place
    execute(<<-SQL)
      UPDATE
        workspaces
      SET
        workspaces_agent_config_version = 0
      WHERE
        workspaces_agent_config_version IS NULL;
    SQL
  end

  def down
    # backfill workspaces_agent_config_version column is irreversible
  end
end
