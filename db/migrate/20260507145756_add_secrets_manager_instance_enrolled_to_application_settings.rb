# frozen_string_literal: true

class AddSecretsManagerInstanceEnrolledToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def up
    add_column :application_settings, :secrets_manager_instance_enrolled, :boolean,
      default: false, null: false, if_not_exists: true
  end

  def down
    remove_column :application_settings, :secrets_manager_instance_enrolled, if_exists: true
  end
end
