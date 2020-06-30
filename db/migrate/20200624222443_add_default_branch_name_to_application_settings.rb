# frozen_string_literal: true

class AddDefaultBranchNameToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in db/migrate/20200625190458_add_limit_to_default_branch_name_to_application_settings
  def change
    add_column :application_settings, :default_branch_name, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
