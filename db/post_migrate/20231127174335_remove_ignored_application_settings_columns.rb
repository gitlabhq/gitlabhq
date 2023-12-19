# frozen_string_literal: true

class RemoveIgnoredApplicationSettingsColumns < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  PROJECT_INDEX_NAME = 'index_applicationsettings_on_instance_administration_project_id'
  GROUP_INDEX_NAME = 'index_application_settings_on_instance_administrators_group_id'

  def up
    remove_column(:application_settings, :instance_administration_project_id)
    remove_column(:application_settings, :instance_administrators_group_id)
  end

  def down
    unless column_exists?(:users, :instance_administration_project_id)
      add_column(:application_settings, :instance_administration_project_id, :bigint)
    end

    unless column_exists?(:users, :instance_administrators_group_id)
      add_column(:application_settings, :instance_administrators_group_id, :integer)
    end

    add_concurrent_index(:application_settings, :instance_administration_project_id, name: PROJECT_INDEX_NAME)
    add_concurrent_index(:application_settings, :instance_administrators_group_id, name: GROUP_INDEX_NAME)
  end
end
