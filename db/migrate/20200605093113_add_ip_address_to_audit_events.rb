# frozen_string_literal: true

class AddIpAddressToAuditEvents < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :audit_events, :ip_address, :inet
  end
end
