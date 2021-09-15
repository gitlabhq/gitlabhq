# frozen_string_literal: true

class SetDefaultJobTokenScopeFalse < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      change_column_default :project_ci_cd_settings, :job_token_scope_enabled, from: true, to: false
    end
  end

  def down
    with_lock_retries do
      change_column_default :project_ci_cd_settings, :job_token_scope_enabled, from: false, to: true
    end
  end
end
