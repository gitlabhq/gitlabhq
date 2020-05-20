# frozen_string_literal: true

class ChangeVerificationChecksumFieldTypeInPackageFile < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    # The use of this column is behind a feature flag that never got enabled,
    # so it's safe to remove it in a normal migration
    remove_column :packages_package_files, :verification_checksum, :string # rubocop:disable Migration/RemoveColumn
    add_column :packages_package_files, :verification_checksum, :binary
  end

  def down
    remove_column :packages_package_files, :verification_checksum, :binary
    add_column :packages_package_files, :verification_checksum, :string
  end
end
