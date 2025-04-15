# frozen_string_literal: true

class RemoveDefaultFromResourceIterationEventsNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    change_column_default :resource_iteration_events, :namespace_id, from: 0, to: nil
  end
end
