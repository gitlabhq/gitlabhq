# frozen_string_literal: true

class AddBioToUserDetails < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # rubocop:disable Migration/PreventStrings
  def up
    # rubocop:disable Migration/AddColumnWithDefault
    add_column_with_default(:user_details, :bio, :string, default: '', allow_null: false, limit: 255)
    # rubocop:enable Migration/AddColumnWithDefault
  end
  # rubocop:enable Migration/PreventStrings

  def down
    remove_column(:user_details, :bio)
  end
end
