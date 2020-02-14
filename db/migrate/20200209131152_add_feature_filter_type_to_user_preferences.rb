# frozen_string_literal: true

class AddFeatureFilterTypeToUserPreferences < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :user_preferences, :feature_filter_type, :bigint
  end
end
