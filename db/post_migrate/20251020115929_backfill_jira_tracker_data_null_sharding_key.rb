# frozen_string_literal: true

class BackfillJiraTrackerDataNullShardingKey < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!

  BATCH_SIZE = 1000

  def up
    jira_tracker_data_model = define_batchable_model('jira_tracker_data')
    integrations_model = define_batchable_model('integrations')

    jira_tracker_data_model
      .where(group_id: nil, project_id: nil, organization_id: nil)
      .each_batch(of: BATCH_SIZE) do |batch|
      integration_ids = batch.pluck(:integration_id)
      integrations = integrations_model.where(id: integration_ids).index_by(&:id)

      batch.each do |record|
        integration = integrations[record.integration_id]

        record.update(
          project_id: integration.project_id,
          group_id: integration.group_id,
          organization_id: integration.organization_id
        )
      end
    end
  end

  def down
    # no-op
  end
end
