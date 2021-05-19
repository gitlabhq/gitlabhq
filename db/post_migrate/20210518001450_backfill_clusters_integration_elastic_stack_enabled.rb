# frozen_string_literal: true

class BackfillClustersIntegrationElasticStackEnabled < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    ApplicationRecord.connection.execute(<<~SQL.squish)
      INSERT INTO clusters_integration_elasticstack(
        cluster_id,
        enabled,
        chart_version,
        created_at,
        updated_at
      )
        SELECT
          cluster_id,
          true,
          version,
          TIMEZONE('UTC', NOW()),
          TIMEZONE('UTC', NOW())
        FROM clusters_applications_elastic_stacks
        WHERE status IN (3, 11)
      ON CONFLICT(cluster_id) DO UPDATE SET
        enabled = true,
        updated_at = TIMEZONE('UTC', NOW())
    SQL
  end

  def down
    # Irreversible
  end
end
