# frozen_string_literal: true

class AddCorrelationIdValueToWorkflowsEvents < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  # rubocop:disable Migration/AddLimitToTextColumns -- Limit is added in
  # 20250131175917_add_correlation_id_value_limit_to_duo_workflows_events
  def change
    add_column :duo_workflows_events, :correlation_id_value, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
