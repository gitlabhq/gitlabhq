# frozen_string_literal: true

class AddPagesDomainAcmeOrdersProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    install_sharding_key_assignment_trigger(
      table: :pages_domain_acme_orders,
      sharding_key: :project_id,
      parent_table: :pages_domains,
      parent_sharding_key: :project_id,
      foreign_key: :pages_domain_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :pages_domain_acme_orders,
      sharding_key: :project_id,
      parent_table: :pages_domains,
      parent_sharding_key: :project_id,
      foreign_key: :pages_domain_id
    )
  end
end
