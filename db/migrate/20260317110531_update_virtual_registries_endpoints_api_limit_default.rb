# frozen_string_literal: true

class UpdateVirtualRegistriesEndpointsApiLimitDefault < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '18.11'

  OLD_DEFAULT = 1000
  NEW_DEFAULT = 4000

  def up
    execute <<~SQL
      UPDATE application_settings
      SET rate_limits = jsonb_set(rate_limits, '{virtual_registries_endpoints_api_limit}', '#{NEW_DEFAULT}')
      WHERE rate_limits->>'virtual_registries_endpoints_api_limit' = '#{OLD_DEFAULT}'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE application_settings
      SET rate_limits = jsonb_set(rate_limits, '{virtual_registries_endpoints_api_limit}', '#{OLD_DEFAULT}')
      WHERE rate_limits->>'virtual_registries_endpoints_api_limit' = '#{NEW_DEFAULT}'
    SQL
  end
end
