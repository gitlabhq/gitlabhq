# frozen_string_literal: true

class AddWhatsNewApplicationSetting < ActiveRecord::Migration[6.0]
  def change
    add_column :application_settings, :whats_new_variant, :integer, limit: 2, default: 0
  end
end
