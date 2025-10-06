# frozen_string_literal: true

class RemoveSingletonColumnFromSecurityPolicySettings < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def up
    remove_column :security_policy_settings, :singleton
  end

  def down
    add_column :security_policy_settings, :singleton, :boolean, null: false, default: true,
      comment: 'Always true, used for singleton enforcement'
  end
end
