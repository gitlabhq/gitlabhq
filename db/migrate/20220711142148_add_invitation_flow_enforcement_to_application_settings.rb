# frozen_string_literal: true

class AddInvitationFlowEnforcementToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :invitation_flow_enforcement,
               :boolean,
               default: false,
               null: false
  end
end
