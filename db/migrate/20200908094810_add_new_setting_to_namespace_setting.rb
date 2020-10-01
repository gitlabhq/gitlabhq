# frozen_string_literal: true

class AddNewSettingToNamespaceSetting < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :namespace_settings, :allow_mfa_for_subgroups, :boolean, default: true, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :namespace_settings, :allow_mfa_for_subgroups
    end
  end
end
