# frozen_string_literal: true

class BackfillProjectIssueTrackerDataOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!

  BATCH_SIZE = 1000

  def up
    issue_tracker_data = define_batchable_model('issue_tracker_data')

    issue_tracker_data
      .where.not(project_id: nil)
      .where.not(organization_id: nil)
      .each_batch(of: BATCH_SIZE) do |batch|
      batch.update_all(organization_id: nil)
    end
  end

  def down
    # no-op
  end
end
