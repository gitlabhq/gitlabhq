# frozen_string_literal: true

class AddOrganizationIdToDependencyListExports < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  def change
    add_column :dependency_list_exports, :organization_id, :bigint
  end
end
