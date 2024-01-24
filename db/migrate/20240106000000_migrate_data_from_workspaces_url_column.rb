# frozen_string_literal: true

class MigrateDataFromWorkspacesUrlColumn < Gitlab::Database::Migration[2.2]
  BATCH_SIZE = 500
  DEFAULT_PORT = 60001

  milestone '16.8'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    each_batch_range('workspaces', scope: ->(table) { table.all }, of: BATCH_SIZE) do |min, max|
      execute(<<~SQL)
        UPDATE workspaces
        SET url_prefix = CONCAT('#{DEFAULT_PORT}-', name),
            dns_zone = remote_development_agent_configs.dns_zone,
            url_query_string = CASE
                                    WHEN POSITION('?' IN url) > 0
                                    THEN SUBSTRING(url FROM POSITION('?' IN url) + 1)
                                    ELSE ''
                                END
        FROM
            remote_development_agent_configs
        WHERE
            workspaces.cluster_agent_id = remote_development_agent_configs.cluster_agent_id
        AND url IS NOT NULL
        AND workspaces.id BETWEEN #{min} AND #{max}
      SQL

      execute(<<~SQL)
        UPDATE workspaces
        SET url = NULL
        WHERE workspaces.id BETWEEN #{min} AND #{max}
        AND url_prefix IS NOT NULL
        AND dns_zone IS NOT NULL
        AND url_query_string IS NOT NULL
      SQL
    end
  end

  def down
    each_batch_range('workspaces', scope: ->(table) { table.all }, of: BATCH_SIZE) do |min, max|
      execute(<<~SQL)
        UPDATE workspaces
        SET url = CONCAT(url_prefix, '.', dns_zone, '?', url_query_string)
        WHERE workspaces.id BETWEEN #{min} AND #{max}
      SQL

      execute(<<~SQL)
        UPDATE workspaces
        SET url_prefix = NULL,
            dns_zone = NULL,
            url_query_string = NULL
        WHERE workspaces.id BETWEEN #{min} AND #{max}
      SQL
    end
  end
end
