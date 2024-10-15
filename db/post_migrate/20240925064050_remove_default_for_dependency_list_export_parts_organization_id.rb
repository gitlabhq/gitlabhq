# frozen_string_literal: true

class RemoveDefaultForDependencyListExportPartsOrganizationId < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    change_column_default(:dependency_list_export_parts, :organization_id, from: 1, to: nil)
  end
end
