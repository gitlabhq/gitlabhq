# frozen_string_literal: true

class AddLastCleanupDeletedTagsCountToContainerRepository < Gitlab::Database::Migration[2.0]
  def change
    add_column :container_repositories, :last_cleanup_deleted_tags_count, :integer
  end
end
