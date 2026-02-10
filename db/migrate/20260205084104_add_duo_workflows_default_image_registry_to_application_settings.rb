# frozen_string_literal: true

class AddDuoWorkflowsDefaultImageRegistryToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :application_settings, :duo_workflows_default_image_registry, :text, if_not_exists: true
    end

    add_text_limit :application_settings, :duo_workflows_default_image_registry, 512
  end

  def down
    with_lock_retries do
      remove_column :application_settings, :duo_workflows_default_image_registry, if_exists: true
    end
  end
end
