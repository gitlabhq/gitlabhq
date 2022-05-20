# frozen_string_literal: true

class BulkInsertClusterEnabledGrants < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  disable_ddl_transaction!

  def up
    return unless Gitlab.dev_or_test_env? || Gitlab.com?

    define_batchable_model('cluster_groups').each_batch do |batch|
      min, max = batch.pick('MIN(id), MAX(id)')

      bulk_insert = <<-SQL
        INSERT INTO cluster_enabled_grants (namespace_id, created_at)
        SELECT DISTINCT(traversal_ids[1]), NOW()
        FROM cluster_groups
        INNER JOIN namespaces ON cluster_groups.group_id = namespaces.id
        WHERE cluster_groups.id BETWEEN #{min} AND #{max}
        ON CONFLICT (namespace_id) DO NOTHING
      SQL

      connection.execute(bulk_insert)
    end

    define_batchable_model('cluster_projects').each_batch do |batch|
      min, max = batch.pick('MIN(id), MAX(id)')

      bulk_insert = <<-SQL
        INSERT INTO cluster_enabled_grants (namespace_id, created_at)
        SELECT DISTINCT(traversal_ids[1]), NOW()
        FROM cluster_projects
        INNER JOIN projects ON cluster_projects.project_id = projects.id
        INNER JOIN namespaces on projects.namespace_id = namespaces.id
        WHERE cluster_projects.id BETWEEN #{min} AND #{max}
        ON CONFLICT (namespace_id) DO NOTHING
      SQL

      connection.execute(bulk_insert)
    end
  end

  def down
    # no-op
  end
end
