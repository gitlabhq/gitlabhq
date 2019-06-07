class AddProjectCreationLevelToGroups < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    unless column_exists?(:namespaces, :project_creation_level)
      add_column(:namespaces, :project_creation_level, :integer)
    end
  end

  def down
    if column_exists?(:namespaces, :project_creation_level)
      remove_column(:namespaces, :project_creation_level, :integer)
    end
  end
end
