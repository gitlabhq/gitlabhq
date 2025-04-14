# frozen_string_literal: true

class AddNamespaceIdToDescriptionVersions < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :description_versions, :namespace_id, :bigint, null: false, default: 0 # rubocop:disable Migration/PreventAddingColumns -- Sharding keys are one of the exceptions
  end
end
