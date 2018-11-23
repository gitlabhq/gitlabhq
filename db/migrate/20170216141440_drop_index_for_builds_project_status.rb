# rubocop:disable RemoveIndex
class DropIndexForBuildsProjectStatus < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  def change
    remove_index(:ci_commits, column: [:gl_project_id, :status])
  end
end
