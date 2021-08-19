# frozen_string_literal: true

class RemoveSigningKeysFromPackagesDebianGroupDistributions < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def change
    remove_column :packages_debian_group_distributions, :encrypted_signing_keys, :text
    remove_column :packages_debian_group_distributions, :encrypted_signing_keys_iv, :text
  end
end
