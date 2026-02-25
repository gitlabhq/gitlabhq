# frozen_string_literal: true

class AddDeletionScheduledAtColumn < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    add_timestamps_with_timezone :namespace_details, columns: %i[deletion_scheduled_at], null: true
  end
end
