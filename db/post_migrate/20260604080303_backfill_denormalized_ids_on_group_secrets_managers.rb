# frozen_string_literal: true

class BackfillDenormalizedIdsOnGroupSecretsManagers < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '19.1'

  BATCH_SIZE = 100

  def up
    define_batchable_model('group_secrets_managers').each_batch(of: BATCH_SIZE) do |batch|
      # Live SMs: source from the group's namespace row.
      execute(<<~SQL)
        UPDATE group_secrets_managers
        SET
          organization_id = namespaces.organization_id,
          root_namespace_id = namespaces.traversal_ids[1]
        FROM namespaces
        WHERE namespaces.id = group_secrets_managers.group_id
          AND group_secrets_managers.organization_id IS NULL
          AND group_secrets_managers.id IN (#{batch.select(:id).to_sql})
      SQL

      # Orphan SMs (parent destroyed): parse from the cached
      # root_namespace_path, which is "org_<X>/group_<R>". These rows are
      # slated for deletion in the next migration step
      # (gitlab-org/gitlab#600290), so we only need to satisfy the
      # upcoming NOT NULL constraint.
      execute(<<~SQL)
        UPDATE group_secrets_managers
        SET
          organization_id = substring(root_namespace_path from '^org_(\\d+)/')::bigint,
          root_namespace_id = substring(root_namespace_path from '/group_(\\d+)$')::bigint
        WHERE group_id IS NULL
          AND organization_id IS NULL
          AND root_namespace_path IS NOT NULL
          AND group_secrets_managers.id IN (#{batch.select(:id).to_sql})
      SQL
    end
  end

  def down
    # no-op; backfill is forward-only.
  end
end
