# frozen_string_literal: true

class RemoveCloudConnectorKeysFromApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  # This removes a column that was added in a previous migration that is now a no-op
  # See https://gitlab.com/gitlab-com/gl-infra/production/-/issues/19182
  def up
    # no-op: we need to do this in a separate deploy since the original MR reached canary
  end

  def down
    # no-op since the original migration was turned to a no-op
  end
end
