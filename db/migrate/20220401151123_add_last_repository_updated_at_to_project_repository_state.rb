# frozen_string_literal: true

class AddLastRepositoryUpdatedAtToProjectRepositoryState < Gitlab::Database::Migration[1.0]
  def change
    add_column :project_repository_states, :last_repository_updated_at, :datetime_with_timezone
    add_column :project_repository_states, :last_wiki_updated_at, :datetime_with_timezone
  end
end
