# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class StealMergeRequestDiffCommitUsersMigration < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    job = Gitlab::Database::BackgroundMigrationJob
      .for_migration_class('MigrateMergeRequestDiffCommitUsers')
      .pending
      .last

    return unless job

    # We schedule in one hour so we don't end up running the migrations while a
    # deployment is still wrapping up. Not that that really matters, but it
    # prevents from too much happening during a deployment window.
    migrate_in(1.hour, 'StealMigrateMergeRequestDiffCommitUsers', job.arguments)
  end

  def down
    # no-op
  end
end
