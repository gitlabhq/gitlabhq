# frozen_string_literal: true

class AddMemberApprovalEventsToWebHooks < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :web_hooks, :member_approval_events, :boolean, null: false, default: false
  end
end
