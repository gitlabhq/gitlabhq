# frozen_string_literal: true

class AddStopSettingToEnvironments < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :environments, :auto_stop_setting, :smallint, null: false, default: 0
  end
end
