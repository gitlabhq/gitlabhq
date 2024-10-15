# frozen_string_literal: true

class RemoveDefaultForSbomSourcesOrganizationId < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    change_column_default(:sbom_sources, :organization_id, from: 1, to: nil)
  end
end
