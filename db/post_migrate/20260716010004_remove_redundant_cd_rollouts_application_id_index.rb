# frozen_string_literal: true

class RemoveRedundantCdRolloutsApplicationIdIndex < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.3'

  INDEX_NAME = 'index_cd_rollouts_on_application_id'

  # Covered by index_cd_rollouts_on_application_id_and_iid (application_id leading), which also serves the FK.
  def up
    remove_concurrent_index_by_name :cd_rollouts, INDEX_NAME
  end

  def down
    add_concurrent_index :cd_rollouts, :application_id, name: INDEX_NAME
  end
end
