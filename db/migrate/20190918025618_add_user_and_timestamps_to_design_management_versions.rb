# frozen_string_literal: true

class AddUserAndTimestampsToDesignManagementVersions < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :design_management_versions, :user_id, :integer
    add_column :design_management_versions, :created_at, :datetime_with_timezone
  end

  def down
    remove_columns :design_management_versions, :user_id, :created_at
  end
end
