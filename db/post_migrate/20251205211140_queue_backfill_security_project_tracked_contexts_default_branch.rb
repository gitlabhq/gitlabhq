# frozen_string_literal: true

class QueueBackfillSecurityProjectTrackedContextsDefaultBranch < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    # This migration is removed by migration 20251217173006 because it is very slow.
  end

  def down; end
end
