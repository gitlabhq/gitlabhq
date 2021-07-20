# frozen_string_literal: true

class AddNewUserSignupsCapToNamespaceSettings < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :namespace_settings, :new_user_signups_cap, :integer, null: true
    end
  end

  def down
    with_lock_retries do
      remove_column :namespace_settings, :new_user_signups_cap
    end
  end
end
