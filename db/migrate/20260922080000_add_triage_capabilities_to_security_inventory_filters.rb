# frozen_string_literal: true

class AddTriageCapabilitiesToSecurityInventoryFilters < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    add_column :security_inventory_filters, :triage_capabilities_on, :smallint, default: 0, null: false
    add_column :security_inventory_filters, :triage_capabilities_auto, :smallint, default: 0, null: false
  end
end
