# frozen_string_literal: true

class RemoveDefaultFromResourceStateEventsNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    change_column_default :resource_state_events, :namespace_id, from: 0, to: nil
  end
end
