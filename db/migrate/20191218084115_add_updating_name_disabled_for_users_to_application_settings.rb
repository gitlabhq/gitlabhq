# frozen_string_literal: true

class AddUpdatingNameDisabledForUsersToApplicationSettings < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :updating_name_disabled_for_users,
                            :boolean,
                            default: false,
                            allow_null: false)
  end

  def down
    remove_column(:application_settings, :updating_name_disabled_for_users)
  end
end
