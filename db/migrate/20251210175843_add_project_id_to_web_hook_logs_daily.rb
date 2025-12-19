# frozen_string_literal: true

class AddProjectIdToWebHookLogsDaily < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- required for sharding
    add_column :web_hook_logs_daily, :project_id, :bigint, if_not_exists: true
    # rubocop:enable Migration/PreventAddingColumns
  end
end
