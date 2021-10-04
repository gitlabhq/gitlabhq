# frozen_string_literal: true

class ChangeDefaultForIntegratedErrorTracking < Gitlab::Database::Migration[1.0]
  def up
    change_column_default :project_error_tracking_settings, :integrated, from: false, to: true
  end

  def down
    change_column_default :project_error_tracking_settings, :integrated, from: true, to: false
  end
end
