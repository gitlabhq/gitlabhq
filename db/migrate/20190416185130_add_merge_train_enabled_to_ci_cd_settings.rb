# frozen_string_literal: true

class AddMergeTrainEnabledToCiCdSettings < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # rubocop:disable Migration/UpdateLargeTable
  # rubocop:disable Migration/AddColumnWithDefault
  def up
    add_column_with_default :project_ci_cd_settings, :merge_trains_enabled, :boolean, default: false, allow_null: false
  end
  # rubocop:enable Migration/UpdateLargeTable
  # rubocop:enable Migration/AddColumnWithDefault

  def down
    remove_column :project_ci_cd_settings, :merge_trains_enabled
  end
end
