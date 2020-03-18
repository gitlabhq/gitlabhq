# frozen_string_literal: true

class AddMergeTrainEnabledToCiCdSettings < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # rubocop:disable Migration/AddColumnWithDefault
  # rubocop:disable Migration/UpdateLargeTable
  def up
    add_column_with_default :project_ci_cd_settings, :merge_trains_enabled, :boolean, default: false, allow_null: false
  end
  # rubocop:enable Migration/AddColumnWithDefault
  # rubocop:enable Migration/UpdateLargeTable

  def down
    remove_column :project_ci_cd_settings, :merge_trains_enabled
  end
end
