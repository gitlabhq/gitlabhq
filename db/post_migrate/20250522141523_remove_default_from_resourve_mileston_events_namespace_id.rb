# frozen_string_literal: true

class RemoveDefaultFromResourveMilestonEventsNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    change_column_default :resource_milestone_events, :namespace_id, from: 0, to: nil
  end
end
