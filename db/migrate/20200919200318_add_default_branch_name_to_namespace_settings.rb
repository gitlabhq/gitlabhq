# frozen_string_literal: true

class AddDefaultBranchNameToNamespaceSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns

  # limit is added in 20200919204155_add_text_limit_to_namespace_settings_default_branch_name
  #
  def change
    add_column :namespace_settings, :default_branch_name, :text
  end

  # rubocop:enable Migration/AddLimitToTextColumns
end
