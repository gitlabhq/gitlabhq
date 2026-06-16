# frozen_string_literal: true

class BackfillDenormalizedIdsOnProjectSecretsManagers < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '19.1'

  BATCH_SIZE = 100

  def up
    define_batchable_model('project_secrets_managers').each_batch(of: BATCH_SIZE) do |batch|
      # Live SMs: source from the project + its parent namespace.
      execute(<<~SQL)
        UPDATE project_secrets_managers
        SET
          organization_id = projects.organization_id,
          root_namespace_id = namespaces.traversal_ids[1]
        FROM projects, namespaces
        WHERE projects.id = project_secrets_managers.project_id
          AND namespaces.id = projects.namespace_id
          AND project_secrets_managers.organization_id IS NULL
          AND project_secrets_managers.id IN (#{batch.select(:id).to_sql})
      SQL

      # Orphan SMs (parent destroyed): parse from the cached namespace_path,
      # which is "org_<X>/group_<R>". Rows are slated for deletion in the
      # next migration step (gitlab-org/gitlab#600290) so the parse only
      # needs to satisfy the upcoming NOT NULL constraint.
      execute(<<~SQL)
        UPDATE project_secrets_managers
        SET
          organization_id = substring(namespace_path from '^org_(\\d+)/')::bigint,
          root_namespace_id = substring(namespace_path from '/group_(\\d+)$')::bigint
        WHERE project_id IS NULL
          AND organization_id IS NULL
          AND namespace_path IS NOT NULL
          AND project_secrets_managers.id IN (#{batch.select(:id).to_sql})
      SQL
    end
  end

  def down
    # no-op; backfill is forward-only.
  end
end
