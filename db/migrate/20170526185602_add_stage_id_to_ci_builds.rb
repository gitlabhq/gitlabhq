class AddStageIdToCiBuilds < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :ci_builds, :stage_id, :integer
  end

  def down
    remove_column :ci_builds, :stage_id, :integer
  end
end
