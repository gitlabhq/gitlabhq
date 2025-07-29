# frozen_string_literal: true

class RemoveDefaultFromResourceLabelEventsNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    change_column_default :resource_label_events, :namespace_id, from: 0, to: nil
  end
end
