# frozen_string_literal: true

class AddRemoveDormantMembersPeriodToNamespaceSettings < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :namespace_settings, :remove_dormant_members_period, :integer, default: 90, null: false
  end
end
