# frozen_string_literal: true

class AddSeatAssignmentModelToNamespaceSettings < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_column :namespace_settings, :seat_assignment_model_enabled, :boolean, default: false, null: false
  end
end
