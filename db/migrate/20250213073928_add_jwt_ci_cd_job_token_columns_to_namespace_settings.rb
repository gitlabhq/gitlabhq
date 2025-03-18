# frozen_string_literal: true

class AddJwtCiCdJobTokenColumnsToNamespaceSettings < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :namespace_settings, :jwt_ci_cd_job_token_enabled, :boolean, default: false, null: false
    add_column :namespace_settings, :jwt_ci_cd_job_token_opted_out, :boolean, default: false, null: false
  end
end
