# frozen_string_literal: true

class AddTargetDetailsToAuditEvent < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      # rubocop:disable Migration/AddLimitToTextColumns
      add_column(:audit_events, :target_details, :text)
      # rubocop:enable Migration/AddLimitToTextColumns
    end
  end

  def down
    with_lock_retries do
      remove_column(:audit_events, :target_details)
    end
  end
end
