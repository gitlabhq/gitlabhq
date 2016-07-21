class NullifyHasExternalWikiInProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    execute("UPDATE projects SET has_external_wiki = NULL")
  end

  def down
  end
end
