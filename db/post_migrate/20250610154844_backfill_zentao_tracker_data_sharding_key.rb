# frozen_string_literal: true

class BackfillZentaoTrackerDataShardingKey < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell
  disable_ddl_transaction!

  class Integration < MigrationRecord
    self.table_name = 'integrations'
    self.inheritance_column = :_type_disabled
  end

  def up
    tracker_data = define_batchable_model('zentao_tracker_data')

    tracker_data.each_batch do |batch|
      batch.where(project_id: nil, group_id: nil, organization_id: nil).find_each do |record|
        integration = Integration.find_by_id(record.integration_id)

        next unless integration

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
