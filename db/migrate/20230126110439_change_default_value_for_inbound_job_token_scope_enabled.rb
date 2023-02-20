# frozen_string_literal: true

class ChangeDefaultValueForInboundJobTokenScopeEnabled < Gitlab::Database::Migration[2.1]
  def up
    change_column_default :project_ci_cd_settings, :inbound_job_token_scope_enabled, from: false, to: true
  end

  def down
    change_column_default :project_ci_cd_settings, :inbound_job_token_scope_enabled, from: true, to: false
  end
end
