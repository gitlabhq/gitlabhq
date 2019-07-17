# frozen_string_literal: true

class DropProjectFeaturesPagesAccessLevelDefault < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  ENABLED_VALUE = 20

  def change
    change_column_default :project_features, :pages_access_level, from: ENABLED_VALUE, to: nil
  end
end
