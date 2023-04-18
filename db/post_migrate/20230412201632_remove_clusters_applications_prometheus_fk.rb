# frozen_string_literal: true

class RemoveClustersApplicationsPrometheusFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:clusters_applications_prometheus, column: :cluster_id)
    end
  end

  def down
    add_concurrent_foreign_key :clusters_applications_prometheus, :clusters,
      column: :cluster_id, on_delete: :cascade, name: 'fk_557e773639'
  end
end
