# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ChangeInstanceStatsVisibilityDefault < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_default :application_settings,
                          :instance_statistics_visibility_private,
                          true
    ApplicationSetting.update_all(instance_statistics_visibility_private: true)
  end

  def down
    change_column_default :application_settings,
                          :instance_statistics_visibility_private,
                          false
  end
end
