# frozen_string_literal: true

class AddSkillguardToSecurityInventoryFilters < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  def change
    add_column :security_inventory_filters, :skillguard, :smallint, default: 0, null: false
  end
end
