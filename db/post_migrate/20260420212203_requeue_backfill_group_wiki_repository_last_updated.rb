# frozen_string_literal: true

class RequeueBackfillGroupWikiRepositoryLastUpdated < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillGroupWikiRepositoryLastUpdated"
  SUB_BATCH_SIZE = 100

  def up
    delete_batched_background_migration(MIGRATION, :group_wiki_repositories, :group_id, [])

    queue_batched_background_migration(
      MIGRATION,
      :group_wiki_repositories,
      :group_id,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :group_wiki_repositories, :group_id, [])
  end
end
