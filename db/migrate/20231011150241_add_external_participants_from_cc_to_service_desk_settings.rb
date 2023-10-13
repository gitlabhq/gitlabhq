# frozen_string_literal: true

class AddExternalParticipantsFromCcToServiceDeskSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :service_desk_settings, :add_external_participants_from_cc, :boolean, null: false, default: false
  end
end
