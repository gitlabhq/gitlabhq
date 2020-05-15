# frozen_string_literal: true

class DropProjectCiCdSettingsMergeTrainsEnabled < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_column :project_ci_cd_settings, :merge_trains_enabled
  end

  def down
    # rubocop:disable Migration/AddColumnWithDefault
    add_column_with_default :project_ci_cd_settings, :merge_trains_enabled, :boolean, default: false, allow_null: true # rubocop:disable Migration/UpdateLargeTable
    # rubocop:enable Migration/AddColumnWithDefault
  end
end
