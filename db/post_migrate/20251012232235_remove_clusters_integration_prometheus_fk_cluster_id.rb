# frozen_string_literal: true

class RemoveClustersIntegrationPrometheusFkClusterId < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'fk_rails_e44472034c'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        :clusters_integration_prometheus,
        column: :cluster_id,
        on_delete: :cascade,
        name: CONSTRAINT_NAME
      )
    end
  end

  def down
    add_concurrent_foreign_key(
      :clusters_integration_prometheus,
      :clusters,
      column: :cluster_id,
      on_delete: :cascade,
      name: CONSTRAINT_NAME
    )
  end
end
