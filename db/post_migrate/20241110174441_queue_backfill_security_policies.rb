# frozen_string_literal: true

class QueueBackfillSecurityPolicies < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  MIGRATION = "BackfillSecurityPolicies"

  def up
    # no-op
  end

  def down
    # no-op
  end
end
