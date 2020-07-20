# frozen_string_literal: true

class AddEntityPathToAuditEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      # rubocop:disable Migration/AddLimitToTextColumns
      add_column(:audit_events, :entity_path, :text)
      # rubocop:enable Migration/AddLimitToTextColumns
    end
  end

  def down
    with_lock_retries do
      remove_column(:audit_events, :entity_path)
    end
  end
end
