# frozen_string_literal: true

class BackfillRootNamespacePathOnGroupSecretsManagers < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '18.11'

  BATCH_SIZE = 100

  def up
    define_batchable_model('group_secrets_managers').each_batch(of: BATCH_SIZE) do |batch|
      execute(<<~SQL)
        UPDATE group_secrets_managers
        SET root_namespace_path = 'group_' || namespaces.traversal_ids[1]::text
        FROM namespaces
        WHERE namespaces.id = group_secrets_managers.group_id
        AND group_secrets_managers.id IN (#{batch.select(:id).to_sql})
      SQL
    end
  end

  def down
    # no-op - cannot rollback data changes
  end
end
