# frozen_string_literal: true

# This migration is not needed anymore and was disabled, because we're now
# also backfilling design positions immediately before moving a design.
#
# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/39555
class BackfillDesignsRelativePosition < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    # no-op
  end

  def down
    # no-op
  end
end
