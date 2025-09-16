# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ChangeVirtualRegistriesSettingsDefault < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  TABLE_NAME = :virtual_registries_settings
  def change
    change_column_default(TABLE_NAME, 'enabled', from: false, to: true)
  end
end
