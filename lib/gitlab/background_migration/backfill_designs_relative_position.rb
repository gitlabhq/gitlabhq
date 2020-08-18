# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This migration is not needed anymore and was disabled, because we're now
    # also backfilling design positions immediately before moving a design.
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/39555
    class BackfillDesignsRelativePosition
      def perform(issue_ids)
        # no-op
      end
    end
  end
end
