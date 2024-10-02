# frozen_string_literal: true

class RemoveDefaultForSbomComponentsOrganizationId < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    change_column_default(:sbom_components, :organization_id, from: 1, to: nil)
  end
end
