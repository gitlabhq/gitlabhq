# frozen_string_literal: true

class RemoveServerlessDomainClusterKnativeFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:serverless_domain_cluster, column: :clusters_applications_knative_id)
    end
  end

  def down
    add_concurrent_foreign_key :serverless_domain_cluster, :clusters_applications_knative,
      column: :clusters_applications_knative_id, on_delete: :cascade, name: 'fk_rails_e59e868733'
  end
end
