# frozen_string_literal: true

class BackfillAiGatewayTimeoutSecondsDefault < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  def up
    ApplicationSetting.reset_column_information
    ApplicationSetting.where(ai_gateway_timeout_seconds: 60).update_all(ai_gateway_timeout_seconds: 120)
  end

  def down
    # no-op: `up` assumes every row at 60 was using the old default, but rows explicitly
    # set to 120 can't be told apart from backfilled ones, so reverting could overwrite them.
  end
end
