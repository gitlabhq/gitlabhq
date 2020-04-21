# frozen_string_literal: true

class AddBioToUserDetails < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # rubocop:disable Migration/PreventStrings
  def up
    add_column_with_default(:user_details, :bio, :string, default: '', allow_null: false, limit: 255, update_column_in_batches_args: { batch_column_name: :user_id })
  end
  # rubocop:enable Migration/PreventStrings

  def down
    remove_column(:user_details, :bio)
  end
end
