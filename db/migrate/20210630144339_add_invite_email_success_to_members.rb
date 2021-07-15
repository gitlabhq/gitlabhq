# frozen_string_literal: true

class AddInviteEmailSuccessToMembers < ActiveRecord::Migration[6.1]
  def change
    add_column :members, :invite_email_success, :boolean, null: false, default: true
  end
end
