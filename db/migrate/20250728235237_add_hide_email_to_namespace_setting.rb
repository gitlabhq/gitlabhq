# frozen_string_literal: true

class AddHideEmailToNamespaceSetting < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :namespace_settings, :hide_email_on_profile, :boolean, default: false, null: false
  end
end
