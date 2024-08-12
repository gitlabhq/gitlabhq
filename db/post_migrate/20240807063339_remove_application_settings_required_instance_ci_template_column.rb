# frozen_string_literal: true

class RemoveApplicationSettingsRequiredInstanceCiTemplateColumn < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  enable_lock_retries!

  def up
    remove_column :application_settings, :required_instance_ci_template
  end

  def down
    add_column :application_settings, :required_instance_ci_template, :string
  end
end
