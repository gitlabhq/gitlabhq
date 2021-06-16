# frozen_string_literal: true

class AddJobTokenScopeEnabledToCiCdSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :project_ci_cd_settings, :job_token_scope_enabled, :boolean, default: false, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :project_ci_cd_settings, :job_token_scope_enabled
    end
  end
end
