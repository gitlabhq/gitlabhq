# frozen_string_literal: true

class AddLicensesFieldToPackageMetadataPackages < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :pm_packages, :licenses, :jsonb, null: true
  end
end
