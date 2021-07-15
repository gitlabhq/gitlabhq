# frozen_string_literal: true

class ChangeDefaultJobTokenScopeEnabled < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      change_column_default :project_ci_cd_settings, :job_token_scope_enabled, from: false, to: true
    end
  end

  def down
    with_lock_retries do
      change_column_default :project_ci_cd_settings, :job_token_scope_enabled, from: true, to: false
    end
  end
end
