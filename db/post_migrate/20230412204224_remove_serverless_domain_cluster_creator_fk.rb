# frozen_string_literal: true

class RemoveServerlessDomainClusterCreatorFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:serverless_domain_cluster, column: :creator_id)
    end
  end

  def down
    add_concurrent_foreign_key :serverless_domain_cluster, :users,
      column: :creator_id, on_delete: :nullify, name: 'fk_rails_fbdba67eb1'
  end
end
