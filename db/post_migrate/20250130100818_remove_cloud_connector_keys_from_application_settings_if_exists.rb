# frozen_string_literal: true

class RemoveCloudConnectorKeysFromApplicationSettingsIfExists < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  # Follow-up to RemoveCloudConnectorKeysFromApplicationSettings.
  #
  # This actually removes a column that was added in a previous migration where we had
  # to make this a no-op due to a production issue.
  # See https://gitlab.com/gitlab-com/gl-infra/production/-/issues/19182
  def up
    remove_column(:application_settings, :cloud_connector_keys, if_exists: true)
  end

  def down
    # no-op since the original migration was turned to a no-op and we don't want to
    # add this column back. It was never used.
  end
end
