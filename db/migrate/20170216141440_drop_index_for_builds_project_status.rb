# rubocop:disable RemoveIndex
class DropIndexForBuildsProjectStatus < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  def change
    remove_index(:ci_commits, column: [:gl_project_id, :status])
  end
end
