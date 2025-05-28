# frozen_string_literal: true

class CleanupUntetheredIntegrations < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell
  disable_ddl_transaction!

  BATCH_SIZE = 50

  def up
    integrations = define_batchable_model('integrations')

    integrations.where(instance: false, group_id: nil, project_id: nil).each_batch(of: BATCH_SIZE) do |batch|
      batch.delete_all
    end
  end

  def down
    # no-op
  end
end
