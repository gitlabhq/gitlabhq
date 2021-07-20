# frozen_string_literal: true

class AddProjectSettingsPreviousDefaultBranchTextLimit < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_text_limit :project_settings, :previous_default_branch, 4096
  end

  def down
    remove_text_limit :project_settings, :previous_default_branch
  end
end
