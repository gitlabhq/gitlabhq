# frozen_string_literal: true

class AddTextLimitToProjectSettingsMirrorBranchRegex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_text_limit :project_settings, :mirror_branch_regex, 255
  end

  def down
    remove_text_limit :project_settings, :mirror_branch_regex
  end
end
