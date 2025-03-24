# frozen_string_literal: true

class DropNamespaceIdDefaultFromDescriptionVersions < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    change_column_default :description_versions, :namespace_id, from: 0, to: nil
  end
end
