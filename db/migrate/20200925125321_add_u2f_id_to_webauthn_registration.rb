# frozen_string_literal: true

class AddU2fIdToWebauthnRegistration < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :webauthn_registrations, :u2f_registration_id, :integer
  end
end
