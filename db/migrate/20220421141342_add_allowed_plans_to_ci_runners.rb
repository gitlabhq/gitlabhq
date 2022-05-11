# frozen_string_literal: true

class AddAllowedPlansToCiRunners < Gitlab::Database::Migration[1.0]
  def change
    # rubocop:disable Migration/AddLimitToTextColumns
    add_column :ci_runners, :allowed_plans, :text, array: true, null: false, default: []
    # rubocop:enable Migration/AddLimitToTextColumns
  end
end
