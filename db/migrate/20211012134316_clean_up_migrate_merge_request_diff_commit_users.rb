# frozen_string_literal: true

class CleanUpMigrateMergeRequestDiffCommitUsers < Gitlab::Database::Migration[1.0]
  def up
    jobs = Gitlab::Database::BackgroundMigrationJob
      .for_migration_class('MigrateMergeRequestDiffCommitUsers')
      .pending
      .to_a

    return if jobs.empty?

    say("#{jobs.length} MigrateMergeRequestDiffCommitUsers are still pending")

    # Normally we don't process background migrations in a regular migration, as
    # this could take a while to complete and thus block a deployment.
    #
    # In this case the jobs have all been processed for GitLab.com at the time
    # of writing. In addition, it's been a few releases since this migration was
    # introduced. As a result, self-hosted instances should have their
    # migrations finished a long time ago.
    #
    # For these reasons we clean up any pending jobs (just in case) before
    # deploying the code. This also allows us to immediately start using the new
    # setup only, instead of having to support both the old and new approach for
    # at least one more release.
    jobs.each do |job|
      Gitlab::BackgroundMigration::MigrateMergeRequestDiffCommitUsers
        .new
        .perform(*job.arguments)
    end
  end

  def down
  end
end
