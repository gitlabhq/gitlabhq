# frozen_string_literal: true

class BackfillOrbitNamespaceEnrollmentsBeta < Gitlab::Database::Migration[2.3]
  milestone '19.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!

  BATCH_SIZE = 1_000
  BETA = 1

  def up
    each_batch_range(:knowledge_graph_enabled_namespaces, of: BATCH_SIZE) do |min, max|
      execute(<<~SQL)
        INSERT INTO orbit_namespace_enrollments (namespace_id, source, created_at, updated_at)
        SELECT enabled.root_namespace_id, #{BETA}, NOW(), NOW()
        FROM knowledge_graph_enabled_namespaces enabled
        JOIN namespaces ON namespaces.id = enabled.root_namespace_id
          AND namespaces.type = 'Group' AND namespaces.parent_id IS NULL
        WHERE enabled.id BETWEEN #{min} AND #{max}
        ON CONFLICT (namespace_id) DO NOTHING
      SQL
    end
  end

  def down
    # no-op: rolling back the table migration drops the rows
  end
end
