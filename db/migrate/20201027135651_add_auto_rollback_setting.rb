# frozen_string_literal: true

class AddAutoRollbackSetting < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :project_ci_cd_settings, :auto_rollback_enabled, :boolean, default: false, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :project_ci_cd_settings, :auto_rollback_enabled
    end
  end
end
