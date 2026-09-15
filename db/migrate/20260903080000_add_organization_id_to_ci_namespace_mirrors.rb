# frozen_string_literal: true

class AddOrganizationIdToCiNamespaceMirrors < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_column :ci_namespace_mirrors, :organization_id, :bigint
  end
end
