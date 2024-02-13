# frozen_string_literal: true

class AddVerificationLevelToCatalogResources < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  def change
    add_column :catalog_resources, :verification_level, :integer, limit: 2, default: 0
  end
end
