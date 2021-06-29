# frozen_string_literal: true

class AddLastSyncedAtToLicenses < ActiveRecord::Migration[6.1]
  def change
    add_column :licenses, :last_synced_at, :datetime_with_timezone
  end
end
