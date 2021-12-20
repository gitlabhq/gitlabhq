# frozen_string_literal: true

class AddSettingsUserEmailLookupLimit < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_column :application_settings, :user_email_lookup_limit, :integer, null: false, default: 60
  end

  def down
    remove_column :application_settings, :user_email_lookup_limit
  end
end
