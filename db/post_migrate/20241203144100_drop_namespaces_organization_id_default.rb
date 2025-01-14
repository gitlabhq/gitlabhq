# frozen_string_literal: true

class DropNamespacesOrganizationIdDefault < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    change_column_default(:namespaces, :organization_id, from: 1, to: nil)
  end
end
