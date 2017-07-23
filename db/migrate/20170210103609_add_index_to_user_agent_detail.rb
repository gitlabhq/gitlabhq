# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable RemoveIndex
class AddIndexToUserAgentDetail < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :user_agent_details, [:subject_id, :subject_type]
  end

  def down
    remove_index :user_agent_details, [:subject_id, :subject_type] if index_exists? :user_agent_details, [:subject_id, :subject_type]
  end
end
