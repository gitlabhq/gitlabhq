# frozen_string_literal: true

class DisableExpirationPoliciesLinkedToNoContainerImages < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  BATCH_SIZE = 1000

  class ContainerExpirationPolicy < ActiveRecord::Base
    include ::EachBatch
    self.table_name = 'container_expiration_policies'
  end

  def up
    ContainerExpirationPolicy.where(enabled: true).each_batch(of: BATCH_SIZE) do |batch, _|
      sql = <<-SQL
        WITH batched_relation AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (#{batch.limit(BATCH_SIZE).to_sql})
        UPDATE container_expiration_policies
        SET enabled = FALSE
        FROM batched_relation
        WHERE container_expiration_policies.project_id = batched_relation.project_id
        AND NOT EXISTS (SELECT 1 FROM "container_repositories" WHERE container_repositories.project_id = container_expiration_policies.project_id)
      SQL
      execute(sql)
    end
  end

  def down
    # no-op

    # we can't accuretaly know which policies were previously enabled during `#up`
  end
end
