# frozen_string_literal: true

class AddTypeToDastSiteProfile < ActiveRecord::Migration[6.0]
  def change
    add_column :dast_site_profiles, :target_type, :integer, limit: 2, default: 0, null: false
  end
end
