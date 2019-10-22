# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# TODO: remove this migration after execution on gitlab.com https://gitlab.com/gitlab-org/gitlab/issues/34018
class ScheduleFixGitlabComPagesAccessLevel < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  MIGRATION = 'FixGitlabComPagesAccessLevel'
  BATCH_SIZE = 20_000
  BATCH_TIME = 2.minutes

  # Project
  class Project < ActiveRecord::Base
    include EachBatch

    self.table_name = 'projects'
    self.inheritance_column = :_type_disabled
  end

  disable_ddl_transaction!

  def up
    return unless ::Gitlab.com?

    queue_background_migration_jobs_by_range_at_intervals(
      Project,
      MIGRATION,
      BATCH_TIME,
      batch_size: BATCH_SIZE)
  end

  def down
  end
end
