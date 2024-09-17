# frozen_string_literal: true

class AddApplicationSettingsRequiredInstanceCiTemplateColumn < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :application_settings, :required_instance_ci_template, :text, if_not_exists: true
    end

    add_text_limit :application_settings, :required_instance_ci_template, 1024
  end

  def down
    with_lock_retries do
      remove_column :application_settings, :required_instance_ci_template, if_exists: true
    end
  end
end
