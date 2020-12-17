# frozen_string_literal: true

class AddOtherRoleToUserDetails < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless column_exists?(:user_details, :other_role)
      with_lock_retries do
        add_column :user_details, :other_role, :text
      end
    end

    add_text_limit :user_details, :other_role, 100
  end

  def down
    with_lock_retries do
      remove_column :user_details, :other_role
    end
  end
end
