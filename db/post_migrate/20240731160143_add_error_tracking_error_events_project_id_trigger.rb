# frozen_string_literal: true

class AddErrorTrackingErrorEventsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def up
    install_sharding_key_assignment_trigger(
      table: :error_tracking_error_events,
      sharding_key: :project_id,
      parent_table: :error_tracking_errors,
      parent_sharding_key: :project_id,
      foreign_key: :error_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :error_tracking_error_events,
      sharding_key: :project_id,
      parent_table: :error_tracking_errors,
      parent_sharding_key: :project_id,
      foreign_key: :error_id
    )
  end
end
