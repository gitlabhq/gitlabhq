# frozen_string_literal: true

class AddInstanceStatisticsVisibilityToApplicationSetting < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :instance_statistics_visibility_private,
                            :boolean,
                            default: false,
                            allow_null: false)
  end

  def down
    remove_column(:application_settings, :instance_statistics_visibility_private)
  end
end
