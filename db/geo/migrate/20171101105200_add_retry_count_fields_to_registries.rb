class AddRetryCountFieldsToRegistries < ActiveRecord::Migration
  def change
    add_column :file_registry, :retry_count, :integer
    add_column :project_registry, :repository_retry_count, :integer
    add_column :project_registry, :wiki_retry_count, :integer

    add_column :project_registry, :repository_retry_at, :datetime
    add_column :project_registry, :wiki_retry_at, :datetime
    add_column :file_registry, :retry_at, :datetime
  end
end
