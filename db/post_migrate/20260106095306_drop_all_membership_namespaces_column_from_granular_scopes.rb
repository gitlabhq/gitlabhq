# frozen_string_literal: true

class DropAllMembershipNamespacesColumnFromGranularScopes < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  def change
    remove_column :granular_scopes, :all_membership_namespaces, :boolean, default: false, null: false
  end
end
