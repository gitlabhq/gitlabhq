# frozen_string_literal: true

class AddSecretsManagerInstanceAddOnRequestedAtToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_column :application_settings, :secrets_manager_instance_add_on_requested_at, :datetime_with_timezone
  end
end
