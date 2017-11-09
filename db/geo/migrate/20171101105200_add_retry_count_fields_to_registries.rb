class AddRetryCountFieldsToRegistries < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :file_registry, :retry_count, :integer
    add_column :file_registry, :retry_at, :datetime

    add_column :project_registry, :repository_retry_count, :integer
    add_column :project_registry, :repository_retry_at, :datetime
    add_column :project_registry, :force_to_redownload_repository, :boolean

    add_column :project_registry, :wiki_retry_count, :integer
    add_column :project_registry, :wiki_retry_at, :datetime
    add_column :project_registry, :force_to_redownload_wiki, :boolean

    # Indecies
    add_concurrent_index :file_registry, :retry_at
    add_concurrent_index :project_registry, :repository_retry_at
    add_concurrent_index :project_registry, :wiki_retry_at
  end

  def down
    remove_column :file_registry, :retry_count, :integer
    remove_column :file_registry, :retry_at, :datetime

    remove_column :project_registry, :repository_retry_count, :integer
    remove_column :project_registry, :repository_retry_at, :datetime
    remove_column :project_registry, :force_to_redownload_repository, :boolean

    remove_column :project_registry, :wiki_retry_count, :integer
    remove_column :project_registry, :wiki_retry_at, :datetime
    remove_column :project_registry, :force_to_redownload_wiki, :boolean
  end
end
