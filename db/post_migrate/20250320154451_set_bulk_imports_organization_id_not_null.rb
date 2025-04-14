# frozen_string_literal: true

class SetBulkImportsOrganizationIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    change_column_null(:bulk_imports, :organization_id, false)
  end

  def down
    change_column_null(:bulk_imports, :organization_id, true)
  end
end
