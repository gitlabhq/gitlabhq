# frozen_string_literal: true

class AddBusinessLogicToSecurityInventoryFilters < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    add_column :security_inventory_filters, :business_logic, :smallint, default: 0, null: false
  end
end
