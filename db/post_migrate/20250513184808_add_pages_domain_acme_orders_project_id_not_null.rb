# frozen_string_literal: true

class AddPagesDomainAcmeOrdersProjectIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :pages_domain_acme_orders, :project_id
  end

  def down
    remove_not_null_constraint :pages_domain_acme_orders, :project_id
  end
end
