# frozen_string_literal: true

class AddLastRepositoryUpdatedAtToGroupWikiRepositories < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    add_column :group_wiki_repositories, :last_repository_updated_at, :datetime_with_timezone, null: true
  end
end
