# frozen_string_literal: true

class SeedCloudConnectorKeys < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    # no-op due to https://gitlab.com/gitlab-com/gl-infra/production/-/issues/19182
  end
end
