# frozen_string_literal: true

class AddRequireAdminApprovalAfterUserSignupToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :require_admin_approval_after_user_signup, :boolean, default: false, null: false
  end
end
