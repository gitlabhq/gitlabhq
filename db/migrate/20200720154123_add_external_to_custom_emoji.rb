# frozen_string_literal: true

class AddExternalToCustomEmoji < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :custom_emoji, :external, :boolean, default: true, null: false
  end
end
