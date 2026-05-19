# frozen_string_literal: true

class AddDiffLimitsToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :application_settings, :diff_limits, :jsonb, default: {}, null: false
  end
end
