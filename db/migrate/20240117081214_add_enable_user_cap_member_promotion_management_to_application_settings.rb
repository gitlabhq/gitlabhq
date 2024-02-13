# frozen_string_literal: true

class AddEnableUserCapMemberPromotionManagementToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  def change
    add_column(:application_settings, :enable_member_promotion_management, :boolean, default: false, null: false)
  end
end
