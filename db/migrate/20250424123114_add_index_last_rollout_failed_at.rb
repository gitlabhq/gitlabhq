# frozen_string_literal: true

class AddIndexLastRolloutFailedAt < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '18.0'

  INDEX_NAME = :index_zens_on_last_rollout_failed_at
  TABLE_NAME = :zoekt_enabled_namespaces

  def up
    add_column TABLE_NAME, :last_rollout_failed_at, :datetime_with_timezone, if_not_exists: true
    add_concurrent_index TABLE_NAME, :last_rollout_failed_at, name: INDEX_NAME, using: :btree
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, name: INDEX_NAME
    remove_column TABLE_NAME, :last_rollout_failed_at, if_exists: true
  end
end
