# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable RemoveIndex
class RemoveUnnecessaryIndexes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    remove_index :labels, column: :group_id if index_exists?(:labels, :group_id)
    remove_index :award_emoji, column: :user_id if index_exists?(:award_emoji, :user_id)
    remove_index :ci_builds, column: :commit_id if index_exists?(:ci_builds, :commit_id)
    remove_index :deployments, column: :project_id if index_exists?(:deployments, :project_id)
    remove_index :deployments, column: %w(project_id environment_id) if index_exists?(:deployments, %w(project_id environment_id))
    remove_index :lists, column: :board_id if index_exists?(:lists, :board_id)
    remove_index :milestones, column: :project_id if index_exists?(:milestones, :project_id)
    remove_index :notes, column: :project_id if index_exists?(:notes, :project_id)
    remove_index :users_star_projects, column: :user_id if index_exists?(:users_star_projects, :user_id)
  end

  def down
    add_concurrent_index :labels, :group_id
    add_concurrent_index :award_emoji, :user_id
    add_concurrent_index :ci_builds, :commit_id
    add_concurrent_index :deployments, :project_id
    add_concurrent_index :deployments, %w(project_id environment_id)
    add_concurrent_index :lists, :board_id
    add_concurrent_index :milestones, :project_id
    add_concurrent_index :notes, :project_id
    add_concurrent_index :users_star_projects, :user_id
  end
end
