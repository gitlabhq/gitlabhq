# frozen_string_literal: true

class PackageMetadataSetDefaultNotNull < Gitlab::Database::Migration[2.1]
  def change
    change_column_null(:pm_package_versions, :pm_package_id, false)
  end
end
