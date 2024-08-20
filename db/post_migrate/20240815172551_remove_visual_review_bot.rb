# frozen_string_literal: true

class RemoveVisualReviewBot < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.4'
  VISUAL_REVIEW_BOT_TYPE_ID = 3

  class User < MigrationRecord
    self.table_name = :users
  end

  class GhostUserMigration < MigrationRecord
    self.table_name = :ghost_user_migrations
  end

  def up
    visual_review_bot_id = User.where(user_type: VISUAL_REVIEW_BOT_TYPE_ID).first&.id

    return unless visual_review_bot_id

    GhostUserMigration.create!(user_id: visual_review_bot_id, hard_delete: false)
  end

  def down
    # noop - this is a data migration and can't be reversed
  end
end
