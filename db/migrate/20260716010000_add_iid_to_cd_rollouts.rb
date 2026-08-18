# frozen_string_literal: true

class AddIidToCdRollouts < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.3'

  INDEX_NAME = 'index_cd_rollouts_on_application_id_and_iid'

  def up
    add_column :cd_rollouts, :iid, :integer, if_not_exists: true

    # NULLs are distinct, so existing rows (backfilled in a later post-deploy migration) don't collide.
    add_concurrent_index :cd_rollouts, [:application_id, :iid], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :cd_rollouts, INDEX_NAME
    remove_column :cd_rollouts, :iid, if_exists: true
  end
end
