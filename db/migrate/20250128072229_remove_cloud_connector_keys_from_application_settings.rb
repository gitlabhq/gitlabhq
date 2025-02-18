# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

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
