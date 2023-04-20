# frozen_string_literal: true

class RemoveClustersApplicationsCiliumFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:clusters_applications_cilium, column: :cluster_id)
    end
  end

  def down
    add_concurrent_foreign_key :clusters_applications_cilium, :clusters,
      column: :cluster_id, on_delete: :cascade, name: 'fk_rails_59dc12eea6'
  end
end
