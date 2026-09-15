# frozen_string_literal: true

class AddSecretsManagerInstanceBetaEnrolledToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def up
    add_column :application_settings, :secrets_manager_instance_beta_enrolled, :boolean,
      default: false, null: false, if_not_exists: true
  end

  def down
    remove_column :application_settings, :secrets_manager_instance_beta_enrolled, if_exists: true
  end
end
