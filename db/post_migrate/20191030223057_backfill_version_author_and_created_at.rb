# frozen_string_literal: true

class BackfillVersionAuthorAndCreatedAt < ActiveRecord::Migration[5.2]
  DOWNTIME = false
  MIGRATION = 'BackfillVersionDataFromGitaly'
  BATCH_SIZE = 500

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    self.table_name = 'projects'
    self.inheritance_column = :_type_disabled
  end

  class Issue < ActiveRecord::Base
    self.table_name = 'issues'
    self.inheritance_column = :_type_disabled
  end

  class Version < ActiveRecord::Base
    include EachBatch
    self.table_name = 'design_management_versions'
    self.inheritance_column = :_type_disabled

    # Returns unique issue ids of versions that are not in projects
    # that are pending deletion.
    scope :with_unique_issue_ids, -> do
      versions = Version.arel_table
      issues = Issue.arel_table
      projects = Project.arel_table

      select(versions[:issue_id]).where(
        versions[:author_id].eq(nil).or(
          versions[:created_at].eq(nil)
        ).and(
          issues[:project_id].not_in(
            projects.project(projects[:id]).where(projects[:pending_delete].eq(true))
          )
        )
      ).joins(
        versions.join(issues).on(
          issues[:id].eq(versions[:issue_id])
        ).join_sources
      ).distinct
    end
  end

  # This migration will make around ~1300 UPDATE queries on GitLab.com,
  # one per design_management_versions record as the migration will update
  # each record individually.
  #
  # It will make around 870 Gitaly `ListCommitsByOid` requests on GitLab.com.
  # One for every unique issue with design_management_versions records.
  def up
    return unless Gitlab.ee? # no-op for CE

    Version.with_unique_issue_ids.each_batch(of: BATCH_SIZE) do |versions, index|
      jobs = versions.map { |version| [MIGRATION, [version.issue_id]] }

      BackgroundMigrationWorker.bulk_perform_async(jobs)
    end
  end

  def down
    # no-op
  end
end
