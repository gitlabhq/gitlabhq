# frozen_string_literal: true

class AddProjectIdToMilestoneReleases < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :milestone_releases, :project_id, :bigint
  end
end
