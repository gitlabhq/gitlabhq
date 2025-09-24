# frozen_string_literal: true

class ChangeVirtualRegistriesSettingsDefault < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  TABLE_NAME = :virtual_registries_settings
  def change
    change_column_default(TABLE_NAME, 'enabled', from: false, to: true)
  end
end
