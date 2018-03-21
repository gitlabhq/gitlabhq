# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class SchedulePopulateUntrackedUploadsIfNeeded < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  FOLLOW_UP_MIGRATION = 'PopulateUntrackedUploads'.freeze

  class UntrackedFile < ActiveRecord::Base
    include EachBatch

    self.table_name = 'untracked_files_for_uploads'
  end

  def up
    if table_exists?(:untracked_files_for_uploads)
      process_or_remove_table
    end
  end

  def down
    # nothing
  end

  private

  def process_or_remove_table
    if UntrackedFile.all.empty?
      drop_temp_table
    else
      schedule_populate_untracked_uploads_jobs
    end
  end

  def drop_temp_table
    drop_table(:untracked_files_for_uploads, if_exists: true)
  end

  def schedule_populate_untracked_uploads_jobs
    say "Scheduling #{FOLLOW_UP_MIGRATION} background migration jobs since there are rows in untracked_files_for_uploads."

    bulk_queue_background_migration_jobs_by_range(
      UntrackedFile, FOLLOW_UP_MIGRATION)
  end
end
