# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddYamlLimitConstraints < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  SIZE_CONSTRAINT_NAME = 'app_settings_yaml_max_size_positive'
  DEPTH_CONSTRAINT_NAME = 'app_settings_yaml_max_depth_positive'

  disable_ddl_transaction!

  def up
    add_check_constraint :application_settings, 'max_yaml_size_bytes > 0', SIZE_CONSTRAINT_NAME
    add_check_constraint :application_settings, 'max_yaml_depth > 0', DEPTH_CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :application_settings, SIZE_CONSTRAINT_NAME
    remove_check_constraint :application_settings, DEPTH_CONSTRAINT_NAME
  end
end
