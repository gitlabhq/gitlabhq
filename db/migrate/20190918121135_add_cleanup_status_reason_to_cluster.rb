# frozen_string_literal: true

class AddCleanupStatusReasonToCluster < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    add_column :clusters, :cleanup_status_reason, :text # rubocop:disable Migration/AddLimitToTextColumns
  end
end
