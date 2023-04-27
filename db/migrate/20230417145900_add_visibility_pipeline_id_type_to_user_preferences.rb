# frozen_string_literal: true

class AddVisibilityPipelineIdTypeToUserPreferences < Gitlab::Database::Migration[2.1]
  def change
    add_column :user_preferences, :visibility_pipeline_id_type, :integer, default: 0, limit: 2, null: false
  end
end
