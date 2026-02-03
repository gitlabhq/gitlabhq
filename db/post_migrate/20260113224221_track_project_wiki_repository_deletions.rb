# frozen_string_literal: true

class TrackProjectWikiRepositoryDeletions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.9'

  def up
    track_record_deletions(:project_wiki_repositories)
  end

  def down
    untrack_record_deletions(:project_wiki_repositories)
  end
end
