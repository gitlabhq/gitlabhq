# frozen_string_literal: true

class AddTextLimitToContainerRegistryImportTargetPlan < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :container_registry_import_target_plan, 255
  end

  def down
    remove_text_limit :application_settings, :container_registry_import_target_plan
  end
end
