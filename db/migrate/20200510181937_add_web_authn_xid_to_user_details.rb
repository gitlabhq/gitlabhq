# frozen_string_literal: true

class AddWebAuthnXidToUserDetails < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in subsequent migration
  def change
    add_column :user_details, :webauthn_xid, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
