# frozen_string_literal: true

class MakeCreatedAtNotNullInDesignManagementVersions < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_null :design_management_versions, :created_at, false, Time.now.to_s(:db)
  end

  def down
    change_column_null :design_management_versions, :created_at, true
  end
end
