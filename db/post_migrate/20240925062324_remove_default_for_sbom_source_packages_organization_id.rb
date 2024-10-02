# frozen_string_literal: true

class RemoveDefaultForSbomSourcePackagesOrganizationId < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    change_column_default(:sbom_source_packages, :organization_id, from: 1, to: nil)
  end
end
