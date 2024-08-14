# frozen_string_literal: true

class AddImportPlaceholderLimitsToPlanLimits < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :plan_limits, :import_placeholder_user_limit_tier_1, :integer, null: false, default: 0
    add_column :plan_limits, :import_placeholder_user_limit_tier_2, :integer, null: false, default: 0
    add_column :plan_limits, :import_placeholder_user_limit_tier_3, :integer, null: false, default: 0
    add_column :plan_limits, :import_placeholder_user_limit_tier_4, :integer, null: false, default: 0
  end
end
