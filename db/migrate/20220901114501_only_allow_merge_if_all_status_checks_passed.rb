# frozen_string_literal: true

class OnlyAllowMergeIfAllStatusChecksPassed < Gitlab::Database::Migration[2.0]
  def change
    add_column :project_settings, :only_allow_merge_if_all_status_checks_passed, :boolean, default: false, null: false
  end
end
