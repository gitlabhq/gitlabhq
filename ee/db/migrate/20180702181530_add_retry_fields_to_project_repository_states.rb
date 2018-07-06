class AddRetryFieldsToProjectRepositoryStates < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :project_repository_states, :repository_retry_at, :datetime_with_timezone
    add_column :project_repository_states, :wiki_retry_at, :datetime_with_timezone
    add_column :project_repository_states, :repository_retry_count, :integer
    add_column :project_repository_states, :wiki_retry_count, :integer
  end
end
