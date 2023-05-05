# frozen_string_literal: true

class RenameUserEmailLookupLimitSettingToSearchSettings < Gitlab::Database::Migration[1.0]
  def up
    add_column :application_settings, :search_rate_limit, :integer, null: false, default: 30
    add_column :application_settings, :search_rate_limit_unauthenticated, :integer, null: false, default: 10
  end

  def down
    remove_column :application_settings, :search_rate_limit
    remove_column :application_settings, :search_rate_limit_unauthenticated
  end
end
