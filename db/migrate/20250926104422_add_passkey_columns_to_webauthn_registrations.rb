# frozen_string_literal: true

class AddPasskeyColumnsToWebauthnRegistrations < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  SECOND_FACTOR = 2

  def up
    add_column(
      :webauthn_registrations,
      :authentication_mode,
      :smallint, default: SECOND_FACTOR, null: false
    )

    add_column(
      :webauthn_registrations,
      :passkey_eligible,
      :boolean, default: false, null: false
    )

    add_column(
      :webauthn_registrations,
      :last_used_at,
      :datetime_with_timezone
    )
  end

  def down
    remove_column(
      :webauthn_registrations,
      :authentication_mode
    )

    remove_column(
      :webauthn_registrations,
      :passkey_eligible
    )

    remove_column(
      :webauthn_registrations,
      :last_used_at
    )
  end
end
