# frozen_string_literal: true

class QueueBackfillDefaultOrganizationOwners < Gitlab::Database::Migration[2.2]
  milestone '16.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # no-op
  end

  def down
    # no-op
  end
end
