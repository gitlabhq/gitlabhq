# frozen_string_literal: true

class AddUploadFinishedToPagesDeployments < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  enable_lock_retries!

  def change
    # Existing deployments must be considered `upload_ready` For this reason,
    # the column is created with `default: true`, and then changed to
    # `default: false` in post_migrate/20231115151449_update_pages_deployments_upload_ready_default_value.rb.
    # This way, existing deployments are set as `upload_ready: true`,
    # but new ones are created as `upload_ready: false`
    add_column :pages_deployments, :upload_ready, :boolean, default: true
  end
end
