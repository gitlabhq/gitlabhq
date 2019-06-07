# frozen_string_literal: true

class AddDefaultGitDepthToCiCdSettings < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :project_ci_cd_settings, :default_git_depth, :integer
  end
end
