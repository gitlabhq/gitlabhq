# frozen_string_literal: true

class ReplaceActivationMetricsUniqueIndex < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  disable_ddl_transaction!

  TABLE_NAME = 'activation_metrics'
  INDEX_NAME = 'unique_activation_metric_user_id_namespace_id_and_metric'

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME

    add_concurrent_index TABLE_NAME, [:user_id, :namespace_id, :metric],
      unique: true,
      nulls_not_distinct: true,
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME

    add_concurrent_index TABLE_NAME, [:user_id, :namespace_id, :metric],
      unique: true,
      name: INDEX_NAME
  end
end
