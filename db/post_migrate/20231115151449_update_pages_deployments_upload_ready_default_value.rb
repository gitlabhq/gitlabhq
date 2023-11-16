# frozen_string_literal: true

class UpdatePagesDeploymentsUploadReadyDefaultValue < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  def up
    change_column_default :pages_deployments, :upload_ready, from: true, to: false
  end

  def down
    change_column_default :pages_deployments, :upload_ready, from: false, to: true
  end
end
