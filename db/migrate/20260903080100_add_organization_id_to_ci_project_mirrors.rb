# frozen_string_literal: true

class AddOrganizationIdToCiProjectMirrors < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_column :ci_project_mirrors, :organization_id, :bigint
  end
end
