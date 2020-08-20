# frozen_string_literal: true

class AddDeleteOriginalIndexAtToReindexingTasks < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :elastic_reindexing_tasks, :delete_original_index_at, :datetime_with_timezone
    end
  end

  def down
    with_lock_retries do
      remove_column :elastic_reindexing_tasks, :delete_original_index_at
    end
  end
end
