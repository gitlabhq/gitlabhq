# frozen_string_literal: true

class TruncateSecurityFindingsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    return unless Gitlab.dev_env_or_com?

    with_lock_retries do
      connection.execute('TRUNCATE security_findings RESTART IDENTITY')
    end
  end

  def down
    # no-op
  end
end
