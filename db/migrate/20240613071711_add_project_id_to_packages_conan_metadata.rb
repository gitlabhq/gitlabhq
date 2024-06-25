# frozen_string_literal: true

class AddProjectIdToPackagesConanMetadata < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :packages_conan_metadata, :project_id, :bigint
  end
end
