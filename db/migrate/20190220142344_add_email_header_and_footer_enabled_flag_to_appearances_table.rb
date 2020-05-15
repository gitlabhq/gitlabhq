# frozen_string_literal: true

class AddEmailHeaderAndFooterEnabledFlagToAppearancesTable < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default(:appearances, :email_header_and_footer_enabled, :boolean, default: false) # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column(:appearances, :email_header_and_footer_enabled)
  end
end
