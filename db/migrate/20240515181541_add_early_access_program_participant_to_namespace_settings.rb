# frozen_string_literal: true

class AddEarlyAccessProgramParticipantToNamespaceSettings < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :namespace_settings, :early_access_program_participant, :boolean, null: false, default: false
  end
end
