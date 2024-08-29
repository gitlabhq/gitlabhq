# frozen_string_literal: true

class AddPagesSettingToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :application_settings,
      :pages,
      :jsonb,
      default: {},
      null: false
  end
end
