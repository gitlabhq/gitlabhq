# frozen_string_literal: true

class UpdateInvalidDormantUserSetting < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  # rubocop:disable Layout/LineLength
  def up
    execute("update application_settings set deactivate_dormant_users_period=90 where deactivate_dormant_users_period < 90")
  end
  # rubocop:enable Layout/LineLength

  def down
    # no-op
  end
end
