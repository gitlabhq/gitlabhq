class AddStageIdToCiBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :ci_builds, :stage_id, :integer
  end

  def down
    remove_column :ci_builds, :stage_id, :integer
  end
end
