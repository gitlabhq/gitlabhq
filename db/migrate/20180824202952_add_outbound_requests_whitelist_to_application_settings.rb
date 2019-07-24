# frozen_string_literal: true

class AddOutboundRequestsWhitelistToApplicationSettings < ActiveRecord::Migration[5.1]
  DOWNTIME = false

  def change
    add_column :application_settings, :outbound_local_requests_whitelist, :string, array: true, limit: 255
  end
end
