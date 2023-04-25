# frozen_string_literal: true

class AddVerificationTokenToExternalAeDestinations < Gitlab::Database::Migration[1.0]
  def up
    # rubocop:disable Migration/AddLimitToTextColumns
    add_column :audit_events_external_audit_event_destinations, :verification_token, :text
    # rubocop:enable Migration/AddLimitToTextColumns
  end

  def down
    remove_column :audit_events_external_audit_event_destinations, :verification_token
  end
end
