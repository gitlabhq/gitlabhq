# frozen_string_literal: true

class AddApplicationSettingsContainerRegistryPreImportTagsRateConstraint < Gitlab::Database::Migration[2.0]
  CONSTRAINT_NAME = 'app_settings_container_registry_pre_import_tags_rate_positive'

  disable_ddl_transaction!

  def up
    add_check_constraint :application_settings, 'container_registry_pre_import_tags_rate >= 0', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end
