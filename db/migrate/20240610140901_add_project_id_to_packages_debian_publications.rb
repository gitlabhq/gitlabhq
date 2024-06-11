# frozen_string_literal: true

class AddProjectIdToPackagesDebianPublications < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :packages_debian_publications, :project_id, :bigint
  end
end
