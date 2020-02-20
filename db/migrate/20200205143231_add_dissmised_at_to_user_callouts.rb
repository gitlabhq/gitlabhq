# frozen_string_literal: true

class AddDissmisedAtToUserCallouts < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :user_callouts, :dismissed_at, :datetime_with_timezone
  end
end
