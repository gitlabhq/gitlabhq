# frozen_string_literal: true

class AddExpiresAtToKeys < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :keys, :expires_at, :datetime_with_timezone
  end
end
