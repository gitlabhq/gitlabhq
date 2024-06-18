# frozen_string_literal: true

class AddProjectIdToPackagesDebianProjectDistributionKeys < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :packages_debian_project_distribution_keys, :project_id, :bigint
  end
end
