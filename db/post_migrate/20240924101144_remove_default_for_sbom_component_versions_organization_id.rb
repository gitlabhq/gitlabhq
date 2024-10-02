# frozen_string_literal: true

class RemoveDefaultForSbomComponentVersionsOrganizationId < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    change_column_default(:sbom_component_versions, :organization_id, from: 1, to: nil)
  end
end
