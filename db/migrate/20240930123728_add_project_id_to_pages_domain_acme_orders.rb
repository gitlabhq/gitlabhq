# frozen_string_literal: true

class AddProjectIdToPagesDomainAcmeOrders < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :pages_domain_acme_orders, :project_id, :bigint
  end
end
