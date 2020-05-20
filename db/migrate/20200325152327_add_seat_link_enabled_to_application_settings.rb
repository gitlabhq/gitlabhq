# frozen_string_literal: true

class AddSeatLinkEnabledToApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :seat_link_enabled, # rubocop:disable Migration/AddColumnWithDefault
                            :boolean,
                            default: true,
                            allow_null: false)
  end

  def down
    remove_column(:application_settings, :seat_link_enabled)
  end
end
