# frozen_string_literal: true

class ScheduleBackfillReleasesAuthorId < Gitlab::Database::Migration[2.1]
  MIGRATION = 'BackfillReleasesAuthorId'
  JOB_DELAY_INTERVAL = 2.minutes
  GHOST_USER_TYPE = 5

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class User < MigrationRecord
    self.table_name = 'users'
  end

  class Release < MigrationRecord
    self.table_name = 'releases'
  end

  def up
    unless release_with_empty_author_exists?
      say "There are no releases with empty author_id, so skipping migration #{self.class.name}"
      return
    end

    create_ghost_user if ghost_user_id.nil?

    queue_batched_background_migration(
      MIGRATION,
      :releases,
      :id,
      ghost_user_id,
      job_interval: JOB_DELAY_INTERVAL
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :releases, :id, [ghost_user_id])
  end

  private

  def ghost_user_id
    User.find_by(user_type: GHOST_USER_TYPE)&.id
  end

  def create_ghost_user
    user = User.new
    user.name = 'Ghost User'
    user.username = 'ghost'
    user.email = 'ghost@example.com'
    user.user_type = GHOST_USER_TYPE
    user.projects_limit = 100000

    user.save!
  end

  def release_with_empty_author_exists?
    Release.exists?(author_id: nil)
  end
end
