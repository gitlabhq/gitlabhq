# frozen_string_literal: true

class AddDisableInviteMembersSetting < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  def change
    add_column :namespace_settings, :disable_invite_members, :boolean, null: false, default: false
  end
end
