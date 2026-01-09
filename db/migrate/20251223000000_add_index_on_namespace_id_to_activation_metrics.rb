# frozen_string_literal: true

class AddIndexOnNamespaceIdToActivationMetrics < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  disable_ddl_transaction!

  INDEX_NAME = 'index_activation_metrics_on_namespace_id'

  def up
    add_concurrent_index :activation_metrics, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :activation_metrics, INDEX_NAME
  end
end
