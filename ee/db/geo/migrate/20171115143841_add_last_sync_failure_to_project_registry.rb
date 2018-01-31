class AddLastSyncFailureToProjectRegistry < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :project_registry, :last_repository_sync_failure, :string
    add_column :project_registry, :last_wiki_sync_failure, :string
  end
end
