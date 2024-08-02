# frozen_string_literal: true

class AddProjectIdToErrorTrackingErrorEvents < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :error_tracking_error_events, :project_id, :bigint
  end
end
