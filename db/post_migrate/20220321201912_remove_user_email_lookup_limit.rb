# frozen_string_literal: true

class RemoveUserEmailLookupLimit < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    remove_column :application_settings, :user_email_lookup_limit
  end

  def down
    add_column :application_settings, :user_email_lookup_limit, :integer, null: false, default: 60
  end
end
