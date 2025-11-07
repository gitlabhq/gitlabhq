# frozen_string_literal: true

class AddAllNamespacesToGranularScopes < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    add_column :granular_scopes, :all_membership_namespaces, :boolean, default: false, null: false
  end
end
