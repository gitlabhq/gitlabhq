# frozen_string_literal: true

class AddProjectIdToPackagesMavenMetadata < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :packages_maven_metadata, :project_id, :bigint
  end
end
