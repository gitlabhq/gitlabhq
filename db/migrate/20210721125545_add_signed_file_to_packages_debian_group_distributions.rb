# frozen_string_literal: true

class AddSignedFileToPackagesDebianGroupDistributions < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20210721125637_add_text_limit_to_packages_debian_group_distributions_signed_files
  def change
    add_column :packages_debian_group_distributions, :signed_file, :text
    add_column :packages_debian_group_distributions, :signed_file_store, :integer, limit: 2, default: 1, null: false
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
