# frozen_string_literal: true

class AddProjectIdToPackagesBuildInfos < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :packages_build_infos, :project_id, :bigint
  end
end
