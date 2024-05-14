# frozen_string_literal: true

module Ci
  module StuckBuilds
    class DropCancelingService
      include DropHelpers

      TIMEOUT = 1.hour

      def execute
        Gitlab::AppLogger.info "#{self.class}: Cleaning canceling, timed-out builds"

        drop(canceling_timed_out_builds, failure_reason: :stuck_or_timeout_failure)
      end

      private

      def canceling_timed_out_builds
        Ci::Build
          .canceling
          .created_at_before(TIMEOUT.ago)
          .updated_at_before(TIMEOUT.ago)
          .order(created_at: :asc, project_id: :asc) # rubocop:disable CodeReuse/ActiveRecord -- query optimization
      end
    end
  end
end
