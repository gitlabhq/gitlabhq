# frozen_string_literal: true

class AddMakeProfilePrivateApplicationSetting < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  def change
    add_column(:application_settings, :make_profile_private, :boolean, default: true, null: false)
  end
end
