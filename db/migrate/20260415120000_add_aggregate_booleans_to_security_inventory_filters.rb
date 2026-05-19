# frozen_string_literal: true

class AddAggregateBooleansToSecurityInventoryFilters < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :security_inventory_filters, :has_scanners, :boolean, default: false, null: false
    add_column :security_inventory_filters, :has_failed_or_warning, :boolean, default: false, null: false
    add_column :security_inventory_filters, :has_stale, :boolean, default: false, null: false
  end
end
