# frozen_string_literal: true

class UpdateTopologyServiceConcurrencyLimitDefault < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '19.0'

  OLD_DEFAULT = 200
  NEW_DEFAULT = 40

  def up
    execute <<~SQL
      UPDATE application_settings
      SET topology_service_settings = jsonb_set(topology_service_settings, '{topology_service_concurrency_limit}', '#{NEW_DEFAULT}')
      WHERE topology_service_settings->>'topology_service_concurrency_limit' = '#{OLD_DEFAULT}'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE application_settings
      SET topology_service_settings = jsonb_set(topology_service_settings, '{topology_service_concurrency_limit}', '#{OLD_DEFAULT}')
      WHERE topology_service_settings->>'topology_service_concurrency_limit' = '#{NEW_DEFAULT}'
    SQL
  end
end
