# frozen_string_literal: true

class FinalizeBackfillGoogleInstanceAuditEventDestinations < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # no-op
  end

  def down
    # no-op
  end
end
