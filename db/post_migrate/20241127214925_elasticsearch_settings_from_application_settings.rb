# frozen_string_literal: true

class ElasticsearchSettingsFromApplicationSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.8'

  def up
    # prevent downtime for zero downtime upgrades
    # incident: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/19079
    # no-op
  end

  def down
    # no-op
  end
end
