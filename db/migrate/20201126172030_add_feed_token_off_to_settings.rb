# frozen_string_literal: true

class AddFeedTokenOffToSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :disable_feed_token, :boolean, null: false, default: false
  end
end
