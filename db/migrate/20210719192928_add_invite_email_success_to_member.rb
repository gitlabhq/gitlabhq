# frozen_string_literal: true

class AddInviteEmailSuccessToMember < ActiveRecord::Migration[6.1]
  def up
    unless column_exists?(:members, :invite_email_success)
      add_column :members, :invite_email_success, :boolean, null: false, default: true
    end
  end

  def down
    remove_column :members, :invite_email_success
  end
end
