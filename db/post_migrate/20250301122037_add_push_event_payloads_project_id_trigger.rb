# frozen_string_literal: true

class AddPushEventPayloadsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    install_sharding_key_assignment_trigger(
      table: :push_event_payloads,
      sharding_key: :project_id,
      parent_table: :events,
      parent_sharding_key: :project_id,
      foreign_key: :event_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :push_event_payloads,
      sharding_key: :project_id,
      parent_table: :events,
      parent_sharding_key: :project_id,
      foreign_key: :event_id
    )
  end
end
