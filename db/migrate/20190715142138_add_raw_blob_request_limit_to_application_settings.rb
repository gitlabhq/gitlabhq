# frozen_string_literal: true

class AddRawBlobRequestLimitToApplicationSettings < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :application_settings, :raw_blob_request_limit, :integer, default: 300, null: false
  end
end
