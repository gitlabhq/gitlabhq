# frozen_string_literal: true

class IndexPagesDomainAcmeOrdersOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_pages_domain_acme_orders_on_project_id'

  def up
    add_concurrent_index :pages_domain_acme_orders, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :pages_domain_acme_orders, INDEX_NAME
  end
end
