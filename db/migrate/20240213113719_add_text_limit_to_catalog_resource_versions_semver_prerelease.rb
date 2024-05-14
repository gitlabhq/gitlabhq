# frozen_string_literal: true

class AddTextLimitToCatalogResourceVersionsSemverPrerelease < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.10'

  def up
    add_text_limit :catalog_resource_versions, :semver_prerelease, 255
  end

  def down
    remove_text_limit :catalog_resource_versions, :semver_prerelease
  end
end
