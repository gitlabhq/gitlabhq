# frozen_string_literal: true

class ChangeGroupCrmSettingsEnabledDefault < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  enable_lock_retries!

  def change
    change_column_default('group_crm_settings', 'enabled', from: false, to: true)
  end
end
