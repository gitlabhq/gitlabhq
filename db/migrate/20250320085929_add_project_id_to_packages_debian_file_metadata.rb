# frozen_string_literal: true

class AddProjectIdToPackagesDebianFileMetadata < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :packages_debian_file_metadata, :project_id, :bigint
  end
end
