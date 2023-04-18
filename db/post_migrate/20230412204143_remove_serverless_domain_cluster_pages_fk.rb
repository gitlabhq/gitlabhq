# frozen_string_literal: true

class RemoveServerlessDomainClusterPagesFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:serverless_domain_cluster, column: :pages_domain_id)
    end
  end

  def down
    add_concurrent_foreign_key :serverless_domain_cluster, :pages_domains,
      column: :pages_domain_id, on_delete: :cascade, name: 'fk_rails_c09009dee1'
  end
end
