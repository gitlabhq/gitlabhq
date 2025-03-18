# frozen_string_literal: true

class AddProjectIdToPushEventPayloads < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- needed for sharding key
    add_column :push_event_payloads, :project_id, :bigint
    # rubocop:enable Migration/PreventAddingColumns
  end
end
