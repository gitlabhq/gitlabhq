class ChangeArtifactsSizeColumn < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true

  DOWNTIME_REASON = 'Changing an integer column size requires a full table rewrite.'

  def up
    change_column :ci_builds, :artifacts_size, :integer, limit: 8
  end

  def down
    # do nothing
  end
end
